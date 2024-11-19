//
//  OnboardingUserDefaults.swift
//  Tabi Split
//
//  Created by Elian Richard on 18/11/24.
//

extension UserDefaultsService {
    func setOnboardingStatus (_ value: Bool) {
        setValue(value, forKey: .onboardingStatus)
    }
    
    func getOnboardingStatus () -> Bool {
        if let value = getValue(forKey: .onboardingStatus, ofType: Bool.self) {
            return value
        } else { return false }
    }
}
