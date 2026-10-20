// figma-frame-spec.js: read-only use_figma script that exports Figma frames as a JSON frame spec,
// the input design-sync-reviewer compares against the built SwiftUI (standard §2.3, §3.3).
//
// Use: paste this whole file as the `code` of one use_figma call, with TARGET set to a SECTION id
// (every frame in it) or a list of FRAME ids. Save the returned JSON to the project's
// _reports/design-sync/<YYYY-MM-DD>-<topic>.json and hand that path to the agent.
// It changes nothing in the file: no setters, no node creation, no page edits.

const TARGET = 'SECTION_OR_FRAME_IDS';   // '38:2694' or ['38:2887', '38:2904']
// System chrome from the iOS library is kept as one node (component + variant), never expanded.
const CHROME = /^(Status bar|Tab Bar - iPhone|Home Indicator|Navigation Bar - iPhone|Keyboard|Liquid Glass)/;

const hex = c => '#' + [c.r, c.g, c.b].map(v => Math.round(v * 255).toString(16).padStart(2, '0')).join('').toUpperCase();
const varNames = {};
async function varName(id) {
  if (!(id in varNames)) { const v = await figma.variables.getVariableByIdAsync(id); varNames[id] = v ? v.name : id; }
  return varNames[id];
}
async function paints(list) {
  if (!Array.isArray(list)) return undefined;              // figma.mixed
  const out = [];
  for (const p of list) {
    if (p.visible === false) continue;
    if (p.type !== 'SOLID') { out.push({ type: p.type }); continue; }
    const b = p.boundVariables && p.boundVariables.color;
    out.push(b ? { var: await varName(b.id), hex: hex(p.color) } : { hex: hex(p.color), opacity: p.opacity ?? 1 });
  }
  return out.length ? out : undefined;
}

async function frameSpec(frame) {
  const nodes = [];
  async function walk(n, path, inInstance) {
    if (n.visible === false || n.opacity === 0) return;     // hidden layers and Show X = false slots
    const r = { id: n.id, path: path.join(' / '), type: n.type, y: Math.round(n.absoluteBoundingBox ? n.absoluteBoundingBox.y - frame.absoluteBoundingBox.y : 0) };
    if (n.type === 'TEXT') {
      r.text = n.characters;
      if (inInstance) r.inComponent = true;                 // its fill is the component's, not the screen's
      if (typeof n.fontSize === 'number') r.fontSize = n.fontSize;
      if (n.fontName !== figma.mixed) r.fontStyle = n.fontName.style;
    }
    if ('fills' in n && !(inInstance && n.type !== 'TEXT')) { const f = await paints(n.fills); if (f) r.fills = f; }
    if ('strokes' in n && !inInstance) { const s = await paints(n.strokes); if (s) r.strokes = s; }
    if (n.type === 'INSTANCE') {
      const mc = await n.getMainComponentAsync();
      if (mc) {
        const set = mc.parent && mc.parent.type === 'COMPONENT_SET' ? mc.parent : null;
        r.component = set ? set.name : mc.name;
        if (set) r.variant = mc.variantProperties;
      }
      const props = {};
      for (const [k, v] of Object.entries(n.componentProperties)) if (v.type !== 'VARIANT' && v.type !== 'INSTANCE_SWAP') props[k.split('#')[0]] = v.value;
      if (Object.keys(props).length) r.props = props;
      if (r.component && CHROME.test(r.component)) { r.chrome = true; nodes.push(r); return; }
    }
    // Inside instances only text is kept: its fills and boxes belong to the component, not the screen.
    if (!inInstance || n.type === 'TEXT' || n.type === 'INSTANCE') nodes.push(r);
    if ('children' in n) for (const c of n.children) await walk(c, path.concat(c.name), inInstance || n.type === 'INSTANCE');
  }
  for (const c of frame.children) await walk(c, [c.name], false);
  return { id: frame.id, name: frame.name, size: [frame.width, frame.height], fills: await paints(frame.fills), nodes };
}

const ids = Array.isArray(TARGET) ? TARGET : [TARGET];
const first = await figma.getNodeByIdAsync(ids[0]);
if (!first) throw new Error('No node ' + ids[0]);
let page = first; while (page.type !== 'PAGE') page = page.parent;
await figma.setCurrentPageAsync(page);
let frames = [], section = null;
if (first.type === 'SECTION') { section = { id: first.id, name: first.name }; frames = first.children.filter(c => c.type === 'FRAME'); }
else frames = await Promise.all(ids.map(id => figma.getNodeByIdAsync(id)));
const variables = {};
for (const v of await figma.variables.getLocalVariablesAsync('COLOR')) {
  const val = v.valuesByMode[Object.keys(v.valuesByMode)[0]];
  variables[v.name] = val && 'r' in val ? hex(val) : 'alias';
}
return {
  spec: 'figma-frame-spec/1',
  source: { fileKey: figma.fileKey, page: page.name, section, exportedAt: new Date().toISOString() },
  variables,
  frames: await Promise.all(frames.map(frameSpec)),
};
