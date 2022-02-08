//
//  CoinCapPriceService.swift
//  CryptoTracker
//
//  Created by Frank Bara on 2/7/22.
//

import Foundation
import Combine
import Network
import Accessibility

class CoinCapPriceService: NSObject {
    
    private let session = URLSession(configuration: .default)
    private var wsTask: URLSessionWebSocketTask?
    private var pingTryCount = 0
    
    let coinDictionarySubject = CurrentValueSubject<[String: Coin], Never>([:])
    var coinDictionary: [String: Coin] { coinDictionarySubject.value }
    
    let connectionStateSubject = CurrentValueSubject<Bool, Never>( false )
    var isConnected: Bool { connectionStateSubject.value }
    
    private let monitor = NWPathMonitor()
    
    func connect() {
        let coins = CoinType.allCases
            .map { $0.rawValue }
            .joined(separator: ",")
        
        let url = URL(string: "wss://ws.coincap.io/prices?assets=\(coins)")!
        wsTask = session.webSocketTask(with: url)
        wsTask?.delegate = self
        wsTask?.resume()
        
        self.receiveMessage()
    }
    
    func startMonitorNetworkConnectivity() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if path.status == .satisfied, self.wsTask == nil {
                self.connect()
            }
            
            if path.status != .satisfied {
                self.clearConnection()
            }
        }
        
        monitor.start(queue: .main)
    }
    
    private func receiveMessage() {
        
        wsTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Recieved text message: \(text)")
                    if let data = text.data(using: .utf8){
                        self.onReceiveData(data)
                    }
                case .data(let data):
                    print("Recieved binary message: \(data)")
                    
                    self.onReceiveData(data)
                default:
                    break
                }
                // keep on receiving data
                self.receiveMessage()
                self.schedulePing()
                
            case .failure(let error):
                print("Failed to receive message: \(error.localizedDescription)")
            }
        }
        
    }
    
    private func onReceiveData(_ data: Data) {
        guard let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String:String] else { return }
        
        var newDictionary = [String: Coin]()
        dictionary.forEach { key, value in
            let value = Double(value) ?? 0
            newDictionary[key] = Coin(name: key.capitalized, value: value)
        }
        
        let mergedDictionary = coinDictionary.merging(newDictionary) { $1 }
        
        coinDictionarySubject.send(mergedDictionary)
    }
    
    private func schedulePing() {
        let identifier = self.wsTask?.taskIdentifier ?? -1
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self, let task = self.wsTask,
                  task.taskIdentifier == identifier
            else {
                return
            }
            
            if task.state == .running, self.pingTryCount < 2 {
                self.pingTryCount += 1
                print("Ping: send ping \(self.pingTryCount).")
                task.sendPing { [weak self] error in
                    if let error = error {
                        print("Ping failed: \(error.localizedDescription).")
                    } else if self?.wsTask?.taskIdentifier == identifier {
                        self?.pingTryCount = 0
                    }
                }
                self.schedulePing()
            } else {
                
            }
        }
    }
    
    private func reconnect() {
        self.clearConnection()
        self.connect()
    }
    
    func clearConnection() {
        
        self.wsTask?.cancel()
        self.wsTask = nil
        self.pingTryCount = 0
        self.connectionStateSubject.send(false)
        
    }
    
    deinit {
        coinDictionarySubject.send(completion: .finished)
        connectionStateSubject.send(completion: .finished)
    }
    
    
    
}

extension CoinCapPriceService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // succuessfully connected to server
        self.connectionStateSubject.send(true)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // disconnect from the server
        self.connectionStateSubject.send(false)
    }
}
