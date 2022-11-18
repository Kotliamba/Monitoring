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
        ScrollView {
            VStack(spacing: 20) {
                Section("Memory usage") {
                    VStack {
                        InfoCell(title: "Всего памяти", value: monitoringModel.allStorage)
                        InfoCell(title: "Свободно места", value: monitoringModel.freeStorage)
                        InfoCell(title: "Всего оперативной памяти", value: monitoringModel.totalRamValue)
                    }
                }
                Section("CPU info") {
                    VStack {
                        InfoCell(title: "Всего ядер", value: monitoringModel.cores)
                        InfoCell(title: "Активно ядер", value: monitoringModel.activeCores)
                        InfoCell(title: "Загруженность процессора", value: monitoringModel.cpu)
                    }
                }
                Section("App info") {
                    VStack {
                        InfoCell(title: "id процесса", value: monitoringModel.processId)
                        InfoCell(title: "Имя процесса", value: monitoringModel.processName)
                    }
                }
                Section("System info") {
                    VStack {
                        InfoCell(title: "Версия ПО", value: monitoringModel.iOSVersion)
                        InfoCell(title: "Время с последнего включения", value: monitoringModel.lastRestartTime)
                        InfoCell(title: "Температура", value: monitoringModel.thermalState)
                    }
                }
                Spacer()
                Toggle(isOn:$isToggleOn) {
                    Text("Is updating data")
                }
                .onChange(of: isToggleOn) { _ in monitoringModel.getData() }
                .onAppear { monitoringModel.updateData() }
            }
            .padding(20)
        }
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
