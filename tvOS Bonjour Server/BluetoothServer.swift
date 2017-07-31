//
//  BluetoothServer.swift
//  CoreBluetooth
//
//
//

import Foundation
import CoreBluetooth

//PROTOCOLO PARA ENVIAR MENSAGEM RECEBIDA
protocol BluetoothReciever {
	func reciveData(data: String)
}

class BluetoothServer: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate
{

    // Gerenciador do Bluetooth
    var manager: CBCentralManager!
    
    // Array de Periféricos encontrados
    var perifs:[CBPeripheral] = [] //var peripheral: CBPeripheral?
    
    // Array de caracteristics dos Periféricos
    var caractcs:[CBCharacteristic] = [] //var caract: CBCharacteristic?

    //Set Delegate
	var delegate: BluetoothReciever?
	
    // Um lugar para armazenar o incoming Data
	var data  = NSMutableData()

    // Um timer para setar as subscrições e desubscrições dos periféricos
    var timer:Timer?
    
    
    
	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: init
	///////////////////////////////////////////////////////////////////////////////////////////////////

    // Setando o Bluetooth como estático.
	static let sharedInstance = BluetoothServer()
	
	private override init() {
		super.init()
	}
	
    // Timer Update criado para atualizar o subscription
    func timerUpdate(){
        if perifs.count > 0 {
            for (idx, car) in caractcs.enumerated(){//per in perifs {
                let per = perifs[idx]
                    per.setNotifyValue(false, for: car)
                    per.setNotifyValue(true, for: car)
            }
        }
    }

    // Inicializa o CBCentralManager
    func start() {
		self.manager = CBCentralManager(delegate: self, queue: nil)
	}

    
	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: scan API
	///////////////////////////////////////////////////////////////////////////////////////////////////

    /// Faz o manager buscar por perifericos com base em um serviço específico
	func scanForPheripherals() {
		//NSLog("scanning for peripherals...")

		self.manager.scanForPeripherals(withServices: [Bluetooth.Service], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
	}

    // Para o scaneamento de periféricos
	func stopScan() {
		self.manager.stopScan()
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: CBCentralManagerDelegate
	///////////////////////////////////////////////////////////////////////////////////////////////////
	
    /* centralManagerDidUpdateState é um método de protocolo requerido.
     Normalmente você checaria por outros estados para garantir que o device suporta LE, está ligado, etc. Sabemos que Apple tv suporta. Nessa instância, estamos apenas usando pra aguardar o CBCentralManagerState.PoweredOn, que identifica que o bluetooth da Apple TV está pronto para ser usado
     */
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		guard central.state == .poweredOn else {
            // No app final é importante lidar com todos os outros estados.
			return NSLog("manager is not powered on")
		}
        // se o Bluetooth ta ligado, então... scaneia
		self.scanForPheripherals()
	}
	
    /*
     Callback que é chamado sempre que um periférico é achado anunciando que fornece o mesmo serviço.
     Você tem uma série de medidas para garantir uma boa coneção, como por exemplo, checar a distancia pelo RSSI, que diz a força do sinal.
     */
	func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
		// Reject any where the value is above reasonable range
//		if RSSI.integerValue > -15 {
//			return
//		}
		// Reject if the signal strength is too low to be close enough (Close is around -22dB)
//		if RSSI.integerValue < -35 {
//			return
//		}


        // Considerando que está com um range OK, e agora?
        
        // Checamos se já existe conteúdo no advertisementData. Se existe
        if (advertisementData[CBAdvertisementDataServiceUUIDsKey]![0] != nil){
            //Verificamos se faz parte do nosso serviço.
            if advertisementData[CBAdvertisementDataServiceUUIDsKey]![0] as! CBUUID == Bluetooth.Service{
            //Se faz parte... verificamos se o periférico já está no nosso array de periféricos.
                
                if perifs.filter({$0 == peripheral}).isEmpty { //self.peripheral = peripheral
                    
            // se não faz parte, adicionamos.
                    perifs.append(peripheral)

            // E aí nos conectamos com ele.
                    NSLog("connecting to peripheral...")
                    self.manager.connect(peripheral, options: nil)
                }
            }
        }

	}

    
    
    /* Depois de conectado com o periférico, esse callback é chamado. Agorap precisamos descobrir os serviços e caracteristicas para achar a caracteristica que está sendo transferida. */
	func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        //caso o periférico não tenha sido adicionado no array de periféricos... guard. Não vai cair aqui, mas é uma garantia.
     
        guarder(existsPeripheral: peripheral, ifNotMsg: "Periférico não existe em didConnectPeripheral")

        guard !perifs.filter({$0 == peripheral}).isEmpty else{ //self.peripheral == peripheral else {
			return NSLog("could not connect to peripheral")
		}

        // instituimos essa classe como o delegate do periférico.
        peripheral.delegate = self
        // procuramos pelo serviço desejado.
        peripheral.discoverServices([Bluetooth.Service])
    
	}
	
    /* Para garantir que não vamos ter uma lista de dispositivos periféricos desatualizada, fazemos os updates necessarios nesse callback */
	func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // se não achou o dispositivo, algo errado aconteceu.
        guard !perifs.filter({$0 == peripheral}).isEmpty else{
            //self.peripheral == peripheral else {
            return NSLog("could not disconnect")
        }

		NSLog("disconnected: \(peripheral.name)")
        
        //identificamos a posição do periférico no array de perifericos.
            let idx = perifs.index(where: {$0 == peripheral})!
        
        //removemos do array de caracteristics e de perifs.
            perifs.remove(at: idx)
            caractcs.remove(at: idx)
        
		//self.scanForPheripherals()
	}

    /* Caso não seja conectado direito no self.manager.ConnectPeripheral, deveremos tratar o problema aqui... no caso especifico não precisamos fazer nada. */
	func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
		//NSLog("connection failed: \(error)")
		//self.cleanup()
	}
    
    
	
	///////////////////////////////////////////////////////////////////////////////////////////////////
	//  MARK: CBPeripheralDelegate
	///////////////////////////////////////////////////////////////////////////////////////////////////
	
    
    // Chamado quando o serviço demandado foi encontrado no periférico.
	func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        guarder(existsPeripheral: peripheral, ifNotMsg: "Periférico não existe em didDiscoverServices", error: error)

        
        guard !perifs.filter({$0 == peripheral}).isEmpty && error == nil else{
            //self.peripheral == peripheral else {
            NSLog("error discovering service: \(error)")
            return NSLog("could not discover service")
        }
        
        // faz uma busca pelos diversos serviços do periférico, e descobre as caracteristicas do serviço com as caracteristicas que desejamos.
        for service in peripheral.services ?? [] {
           // print("Discovered service: \(service.UUID)")
            peripheral.discoverCharacteristics([Bluetooth.Characteristics], for: service)
        }
	}
    
    // A caracteristica desejada foi descoberta. A central quer subscrever essa caracteristica, que deixa o periférico saber que nós desejamos saber os dados que isso contém.
	func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        // verifica se o periférico existe...
        
        guarder(existsPeripheral: peripheral, ifNotMsg: "Periférico não existe em didDiscoverCharacteristicsForService", error: error)

        guard !perifs.filter({$0 == peripheral}).isEmpty else{
            //self.peripheral == peripheral else {
            return NSLog("could not discover charact")
        }


        // agora faz um loop por todas as caracteristicas do serviço, e
        
        for characteristics in service.characteristics ?? [] {
            if characteristics.uuid == Bluetooth.Characteristics {
                
                //?? seta que a central quer receber notificações sempre que a caracteristica for encontrada em um dos dispositivos.
                for per in perifs{
                    per.setNotifyValue(true, for: characteristics)
                }
                //provavelmente pode ser
                // peripheral.setNotifyValue(true, forCharacteristic: characteristics)
                
                
                //Se não existe ainda nenhuma caracteristica no array, inicia o timer.
                if(caractcs.count <= 0){
                    timer = Timer.scheduledTimer(timeInterval: 0.005, target: self, selector:   #selector(timerUpdate), userInfo: nil, repeats: true)
                }

                //Se não existe a caracteristica especifica do device no array, adiciona a caracteristica.
                if caractcs.filter({$0 == characteristics}).isEmpty {
                    //self.peripheral = peripheral
                    caractcs.append(characteristics)
                    //  NSLog("connecting to peripheral...")
                }
            }
        }
	}
	
    // Callback que avisa quando mais dados novos chegaram por notificação da caracteristica.
	func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        guarder(existsPeripheral: peripheral, ifNotMsg: "Periférico não existe em didUpdateValueForCharactistic", error: error)
        
        guard !perifs.filter({$0 == peripheral}).isEmpty && error == nil else{
            //self.peripheral == peripheral else {
            NSLog("num perifs: \(perifs.count)")
            return
        }

        //cria uma string com a mensagem passada pela caracteristica.
		let string = String(describing: NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue))


        // se a mensagem é uma END OF MESSAGE
        if string == Bluetooth.EOM {
            let msg = String(data: self.data as Data, encoding: String.Encoding.utf8)
            
            //NSLog("\(string!)")
            
            //Passa a mensagem pelo protocolo
            if delegate != nil {
                delegate?.reciveData(data: msg!)
            }
            
            //Reseta o array de dados.
            self.data.length = 0
            return
        } else {
            // caso contrário... passa os dados por characteristic
            self.data.append(characteristic.value!)
        }
        //!! MUDEI AQUI CRIANDO O ELSE

	}
	
    
    // Peripheral avisa aqui se o subscribe ou unsubscribe aconteceu ou não.
	func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
		if characteristic.uuid != Bluetooth.Characteristics {
			return
		}
		if characteristic.isNotifying {
			//NSLog("notif begin on \(characteristic)")
		}
		else {
			//self.manager.cancelPeripheralConnection(peripheral)
		}
	}
	
    // Função pra ajudar a verificar se o periférico existe nas diversas instâncias.
    func guarder(existsPeripheral peripheral: CBPeripheral, ifNotMsg msg: String, error: NSError? = nil) {
        guard !perifs.filter({$0 == peripheral}).isEmpty && error == nil else {
            //self.peripheral == peripheral else {
            NSLog(msg)
            if let err = error {
                NSLog("Error: \(err)")
            }
            return
        }
    }
    
    
}

