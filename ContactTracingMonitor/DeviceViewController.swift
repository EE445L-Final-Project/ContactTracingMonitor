//
//  DeviceViewController.swift
//  ContactTracingMonitor
//
//  Created by apple on 11/26/20.
//  Copyright © 2020 utexas. All rights reserved.
//

import UIKit
import CoreBluetooth

class DeviceViewController: UIViewController,CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = userTableView.dequeueReusableCell(withIdentifier: "contactCell") as! ContactListTableViewCell
        let contact = userList[indexPath.row]
        let year = (contact.date) % 100
        let month = (Int)(contact.date) / 10000
        let day = (Int)(contact.date - month * 10000) / 100
        let minutes = (Int)(contact.time) / 100
        let seconds = (contact.time) % 100
        cell.contactInfoLabel.text = String("\(contact.userName) at \(minutes):\(seconds) in \(month)/\(day)/\(year)")
        return cell
    }
    
    
    let contactServiceUUID = CBUUID(string: "34D2")
    
    let deviceNameUUID = CBUUID(string: "97FF")
    let userNameUUID = CBUUID(string: "1001")
    let readyUUID = CBUUID(string: "1004")
    let ackUUID = CBUUID(string: "1005")
    
    let dateUUID = CBUUID(string: "0B97")
    let timeUUID = CBUUID(string: "ADC1")
    
    var deviceName: String!
    
    
    var deviceNameCharacteristic: CBCharacteristic!
    var userNameCharacteristic: CBCharacteristic!
    var readyCharacteristic: CBCharacteristic!
    var dateCharacteristic: CBCharacteristic!
    var timeCharacteristic: CBCharacteristic!

    @IBOutlet weak var deviceNameField: UITextField!
    @IBOutlet weak var userTableView: UITableView!
    
    var bluetoothCentral: CBCentralManager!
    var peripheral: CBPeripheral!
    
    var userList = [UserProfile]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        peripheral.delegate = self
        bluetoothCentral.delegate = self
        userTableView.delegate = self
        userTableView.dataSource = self
        
        if peripheral.state == .connected{
            peripheral.discoverServices(nil)
            deviceNameField.text = deviceName
        }
        // Do any additional setup after loading the view.
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {return}
        for service in services {
          print(service)
          peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print(characteristic)
            switch characteristic.uuid {
            case readyUUID:
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                readyCharacteristic = characteristic
            case deviceNameUUID:
                deviceNameCharacteristic = characteristic
            case userNameUUID:
                userNameCharacteristic = characteristic
            case dateUUID:
                dateCharacteristic = characteristic
            case timeUUID:
                timeCharacteristic = characteristic
            default:
                print("Unhandled Characteristic UUID: \(characteristic.uuid)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case readyUUID:
            guard let raw = characteristic.value else { return }
            if(raw[0] == 2){
                let ready = Data([0x02])
                peripheral.writeValue(ready, for: readyCharacteristic, type: .withResponse)
                return
            }
            peripheral.readValue(for: userNameCharacteristic)
        case userNameUUID:
            guard let raw = characteristic.value else { return }
            let nameCount = raw.count - 5
            var name = [UInt8]()
            for index in 0..<nameCount {
                name.append(raw[index])
            }
            let username = String(decoding: name, as: UTF8.self)
            let date = Int(raw[nameCount]) * 10000 + Int(raw[nameCount + 1]) * 100 + Int(raw[nameCount + 2])
            let time = Int(raw[nameCount + 3]) * 100 + Int(raw[nameCount + 4])
            let user = UserProfile(userName: username, date: date, time: time)
            userList.append(user)
            userTableView.reloadData()
            let ready = Data([0x02])
            peripheral.writeValue(ready, for: readyCharacteristic, type: .withResponse)
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    
    @IBAction func disconnect(_ sender: UIButton) {
        bluetoothCentral.cancelPeripheralConnection(peripheral)
        
    }
    
    
    @IBAction func changeDeviceName(_ sender: UIButton) {
        let newName = deviceNameField.text;
        guard let data = newName?.data(using: .utf8) else {return}
        deviceNameField.endEditing(true)
        peripheral.writeValue(data, for: deviceNameCharacteristic, type: .withResponse)
    }
    
    @IBAction func syncTime(_ sender: UIButton) {
        let date = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date) % 100
        var dateData = [UInt8]()
        dateData.append(UInt8(month))
        dateData.append(UInt8(day))
        dateData.append(UInt8(year))
        peripheral.writeValue(Data(dateData), for: dateCharacteristic, type: .withResponse)
        
        let minute = calendar.component(.minute, from: date)
        let hour = calendar.component(.hour, from: date)
        var timeData = [UInt8]()
        timeData.append(UInt8(minute))
        timeData.append(UInt8(hour))
        peripheral.writeValue(Data(timeData), for: timeCharacteristic, type: .withResponse)
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        performSegue(withIdentifier: "toHome", sender: self)
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
          case .unknown:
            print("central.state is .unknown")
          case .resetting:
            print("central.state is .resetting")
          case .unsupported:
            print("central.state is .unsupported")
          case .unauthorized:
            print("central.state is .unauthorized")
          case .poweredOff:
            print("central.state is .poweredOff")
          case .poweredOn:
            print("central.state is .poweredOn")
        }
    }
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "toHome" {
            if let nextViewController = segue.destination as? HomeViewController {
                nextViewController.bluetoothCentral = bluetoothCentral
            }
        }
        
    }
}

extension DeviceViewController{
    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self,
                         action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideKeyboard() {
        deviceNameField.endEditing(true)
    }
}
