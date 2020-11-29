//
//  ViewController.swift
//  ContactTracingMonitor
//
//  Created by apple on 11/22/20.
//  Copyright © 2020 utexas. All rights reserved.
//

import UIKit
import CoreBluetooth


class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate{
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = deviceTableView.dequeueReusableCell(withIdentifier: "Default") as! DeviceTableViewCell
        cell.deviceName.text = deviceName[indexPath.row]
        return cell
    }
    

    @IBOutlet weak var startSwitch: UISwitch!
    @IBOutlet weak var deviceTableView: UITableView!
    
    
    var bluetoothCentral: CBCentralManager!
    var connectedPeripheral: CBPeripheral!
    var connectedDeviceName: String!
    

    var deviceName = [String]()
    var deviceList = [CBPeripheral]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        bluetoothCentral = CBCentralManager(delegate: self, queue: nil)
        deviceTableView.delegate = self
        deviceTableView.dataSource = self
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        if(startSwitch.isOn){
            if(bluetoothCentral.state == .poweredOn){
                bluetoothCentral.scanForPeripherals(withServices: nil)
            }else{
                let alert = UIAlertController(title: "Bluetooth is off", message: "Please Turn on your Bluetooth in Settings", preferredStyle: .alert)
                let actionOk = UIAlertAction(title: "OK",
                        style: .default,
                        handler: {(alert: UIAlertAction!) in
                            self.startSwitch.setOn(false, animated: true)
                        })
                alert.addAction(actionOk)
                self.present(alert, animated: true, completion: nil)
                
            }
        }else{
            bluetoothCentral.stopScan()
            deviceName.removeAll()
            deviceList.removeAll()
            deviceTableView.reloadData()
        }
    }
    
    
    @IBAction func tryToConnect(_ sender: UIButton) {
        guard let row = deviceTableView.indexPathForSelectedRow?.row else{
            let alert = UIAlertController(title: "No Device Selected", message: "Please Select a device to Connect", preferredStyle: .alert)
            let actionOk = UIAlertAction(title: "OK",
                    style: .default,
                    handler: nil)
            alert.addAction(actionOk)
            self.present(alert, animated: true, completion: nil)
            return
        }
        bluetoothCentral.connect(deviceList[row])
        connectedPeripheral = deviceList[row]
        connectedDeviceName = deviceName[row]
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        performSegue(withIdentifier: "toDevice", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDevice" {
            if let nextViewController = segue.destination as? DeviceViewController {
                nextViewController.bluetoothCentral = bluetoothCentral
                nextViewController.peripheral = connectedPeripheral
                nextViewController.deviceName = connectedDeviceName
            }
        }
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
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data else{ return }
        assert(manufacturerData.count >= 4)
        let specialID = UInt16(manufacturerData[2]) << 8 + UInt16(manufacturerData[3])
        if(specialID == 0x00FF){        //find our devices
            guard let name = advertisementData["kCBAdvDataLocalName"] as? String else{ return }
            deviceName.append(name)
            deviceList.append(peripheral)
        }
        deviceTableView.reloadData()
    }

}

