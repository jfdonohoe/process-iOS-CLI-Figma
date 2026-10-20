import HealthKit

@Observable
final class HeartRateReader {
    private let store = HKHealthStore()
    var bpm: Double?

    func authorize() async throws {
        let heartRate = HKQuantityType(.heartRate)
        let mindful = HKCategoryType(.mindfulSession)
        try await store.requestAuthorization(toShare: [mindful], read: [heartRate])
    }

    func saveSession(start: Date, end: Date) async throws {
        let sample = HKCategorySample(type: HKCategoryType(.mindfulSession), value: 0, start: start, end: end)
        try await store.save(sample)
    }
}
