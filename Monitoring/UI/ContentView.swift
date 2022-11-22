//
//  ContentView.swift
//  Monitoring
//
//  Created by Чаусов Николай on 18.11.2022.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var monitoringModel = MonitoringModel()
    @State private var isToggleOn = false
    
    var body: some View {
        VStack {
            Text("Технические характеристики")
                .fontWeight(.bold)
            Toggle(isOn:$isToggleOn) {
                Text("Обновление включено")
            }
            .padding(10)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 1)
                    .background(.gray)
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Section("Использование памяти") {
                        VStack {
                            InfoCell(title: "Всего памяти", value: monitoringModel.allStorage)
                            InfoCell(title: "Свободно места", value: monitoringModel.freeStorage)
                            InfoCell(title: "Всего оперативной памяти", value: monitoringModel.totalRamValue)
                            InfoCell(title: "Используемая оперативная память", value: monitoringModel.usedRamValue)
                        }
                    }
                    Section("CPU") {
                        VStack {
                            InfoCell(title: "Процессор", value: monitoringModel.chipName)
                            InfoCell(title: "Максимальная частота", value: monitoringModel.frequency)
                            InfoCell(title: "Всего ядер", value: monitoringModel.cores)
                            InfoCell(title: "Активно ядер", value: monitoringModel.activeCores)
                            InfoCell(title: "Загруженность процессора", value: monitoringModel.cpu)
                        }
                    }
                    Section("Процессы") {
                        VStack {
                            InfoCell(title: "id процесса", value: monitoringModel.processId)
                            InfoCell(title: "Имя процесса", value: monitoringModel.processName)
                        }
                    }
                    Section("Система") {
                        VStack {
                            InfoCell(title: "Имя хоста", value: monitoringModel.userName)
                            InfoCell(title: "Устройство", value: monitoringModel.modelName)
                            InfoCell(title: "Версия ПО", value: monitoringModel.iOSVersion)
                            InfoCell(title: "Время с последнего включения", value: monitoringModel.lastRestartTime)
                            InfoCell(title: "Температура", value: monitoringModel.thermalState)
                            InfoCell(title: "Яркость экрана", value: monitoringModel.brightness)
                        }
                    }
                    Section("Батерея") {
                        VStack {
                            InfoCell(title: "Уровень заряда", value: monitoringModel.batteryLevel)
                            InfoCell(title: "Состояние батареи", value: monitoringModel.batteryState)
                            InfoCell(title: "Режим сбережения", value: monitoringModel.isLowPowerEnabled)
                        }
                    }
                    .onChange(of: isToggleOn) { _ in monitoringModel.enablePublishing() }
                    .onAppear { monitoringModel.updateData() }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }
}

struct InfoCell: View {
    
    let title: String
    var value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
        .padding(10)
        .border(Color.gray)
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView()
    }
}
