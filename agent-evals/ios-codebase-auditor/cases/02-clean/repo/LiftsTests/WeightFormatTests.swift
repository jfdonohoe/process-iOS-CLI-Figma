import XCTest
@testable import Lifts

final class WeightFormatTests: XCTestCase {
    private let en = Locale(identifier: "en_US")

    func testWholeKilogramsHaveNoDecimal() {
        XCTAssertEqual(WeightFormat.label(kilograms: 60, locale: en), "60 kg")
    }

    func testHalfKilogramsKeepOneDecimal() {
        XCTAssertEqual(WeightFormat.label(kilograms: 37.5, locale: en), "37.5 kg")
    }

    func testQuarterKilogramsRoundToOneDecimal() {
        XCTAssertEqual(WeightFormat.label(kilograms: 21.25, locale: en), "21.2 kg")
    }
}
