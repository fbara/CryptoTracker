//
//  MenuBarCoinView.swift
//  CryptoTracker
//
//  Created by Frank Bara on 2/4/22.
//

import SwiftUI

struct MenuBarCoinView: View {
    
    var body: some View {
        
        HStack(spacing: 4) {
            Image(systemName: "circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .trailing, spacing: -2) {
                Text("Bitcoin")
                Text("$40,000")
            }
            .font(.caption)
        }
    }
}

struct MenuBarCoinView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarCoinView()
    }
}
