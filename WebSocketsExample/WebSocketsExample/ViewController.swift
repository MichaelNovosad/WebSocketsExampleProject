//
//  ViewController.swift
//  WebSocketsExample
//
//  Created by Michael Novosad on 18.11.2022.
//

import UIKit

class ViewController: UIViewController {

    private var webSocket: URLSessionWebSocketTask?

    private let closeButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBlue

        closeButton.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        view.addSubview(closeButton)
        closeButton.center = view.center
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        let session = URLSession(configuration: .default,
                                 delegate: self,
                                 delegateQueue: OperationQueue())
        let url = URL(string: "wss://demo.piesocket.com/v3/channel_123?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV&notify_self")
        webSocket = session.webSocketTask(with: url!)
        webSocket?.resume()
    }

    func ping() {
        webSocket?.sendPing { error in
            if let error = error {
                print("Ping error: \(error)")
            }
        }
    }

    @objc
    func close() {
        webSocket?.cancel(with: .goingAway, reason: "Demo ended".data(using: .utf8))
    }

    func send() {
        DispatchQueue.global().asyncAfter(deadline: .now()+1) { [weak self] in
            self?.webSocket?.send(.string("Send new message \(Int.random(in: 0...1000))"), completionHandler: { error in
                if let error = error {
                    print("Send error: \(error)")
                } else {
                    self?.send()
                }
            })
        }
    }

    func receive() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Got data: \(data)")
                case .string(let string):
                    print("Got string: \(string)")
                @unknown default:
                    break
                }
            case .failure(let failure):
                print("receive error: \(failure)")
            }
            self?.receive()
        }
    }
}

// MARK: - Helpers

extension ViewController: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Connection is opened. Did connect to socket")
        ping()
        receive()
        send()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Connection is closed.")
    }
}
