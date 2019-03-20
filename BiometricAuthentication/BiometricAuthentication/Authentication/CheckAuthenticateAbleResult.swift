//
//  CheckAuthenticateAbleResult.swift
//  BiometricAuthentication
//
//  Created by linjj on 2018/12/13.
//  Copyright © 2018 Rushi Sangani. All rights reserved.
//

import Foundation

public enum CheckAuthenticateAbleResult<T> {
    case success
    case failure(T?)
}


