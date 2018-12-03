//
//  TaskManager.swift
//  TrainngProject
//
//  Created by Shay markovich on 03/12/2018.
//  Copyright © 2018 Shay markovich. All rights reserved.
//

import Foundation

protocol TaskManager {
//    func addTask(body: @escaping ((Task) -> Void))
//    func cancelAll()
    func start()
}

protocol Task {
    func finish()
}

class TaskManagerTask: Task {
    private let finishBlock: ()-> Void
    
    init (finishBlock: @escaping ()-> Void){
        self.finishBlock = finishBlock
    }
    
    func finish() {
        finishBlock()
    }
}


class TaskManagerImplBuilder {
    
    private let manager = TaskManagerImpl()
    
    func addTask(body: @escaping ((Task) -> Void)) -> TaskManagerImplBuilder{
        manager.addTask(body: body)
        return self
    }
    
    func cancelAll(){
        manager.cancelAll()
    }
    
    func build()->TaskManager{
        return manager
    }
}

class TaskManagerImpl: TaskManager {
    
    private let dispachGroup = DispatchGroup()
    
    let serialQueue = DispatchQueue(label: "queuename")
    
    private var queque : Queue<((Task) -> Void)> = Queue()
    
    private var isInProcess = false
    
    func addTask(body: @escaping ((Task) -> Void)){
        queque.enqueue(body)
    }
    
    func start(){
        
        if(isInProcess == false) {
            continueTasks()
        } else {
            print("already in process !")
        }
        
    }
    
    func cancelAll(){
        queque.removeAll()
        isInProcess = false
    }
    
    private func executeTask(task: @escaping (Task) -> ()){
        serialQueue.async {
        
            self.dispachGroup.enter()
            
            task(TaskManagerTask(finishBlock:{ [weak self] in
                self?.dispachGroup.leave()
            }))
            
            self.dispachGroup.wait()
            self.continueTasks()
        }
    }
    
    private func continueTasks(){
         if let nextTask = queque.dequeue() {
            isInProcess = true
            executeTask(task: nextTask)
        } else {
            isInProcess = false
        }
    }
}

class Testing {
    
    func start(){
        
        var globalDelayTime = 1
        
        let builder = TaskManagerImplBuilder()
            
        builder
        .addTask { [weak self] (task) in
            self?.testLongFunction(delayTime: 1) {
                globalDelayTime = globalDelayTime + 1
                task.finish()
            }
        }
        .addTask { [weak self] (task) in
            self?.testLongFunction(delayTime: 2) {
                globalDelayTime = globalDelayTime + 1
                builder.cancelAll()
                task.finish()
            }
        }
        .addTask { [weak self] (task) in
                self?.testLongFunction(delayTime: 3) {
                    globalDelayTime = globalDelayTime + 1
                   task.finish()
                }
        }
        .build().start()
        print("continue2")
        
    }
    
    func startRegular(){
//        let taskManager: TaskManager = TaskManagerImpl()
//
//        var globalDelayTime = 1
//
//                taskManager.addTask { [weak self] (task) in
//                    self?.testLongFunction(delayTime: 1) {
//                        globalDelayTime = globalDelayTime + 1
//                        task.finishTask()
//                    }
//                }
//                print("one added")
//                taskManager.addTask { [weak self] (task) in
//                    self?.testLongFunction(delayTime: 2) {
//                        globalDelayTime = globalDelayTime + 1
//                        taskManager.cancelAll()
//                        task.finishTask()
//                    }
//                }
//                 print("two added")
//                taskManager.addTask { [weak self] (task) in
//                    self?.testLongFunction(delayTime: 3) {
//                        globalDelayTime = globalDelayTime + 1
//                        task.finishTask()
//                    }
//                }
//                 print("three added")
//        
//                taskManager.start()
//                print("continue")
//        
    }
        
    
    func testLongFunction(delayTime: Int, complition: @escaping ()->Void){
        DispatchQueue.global().async {
            print("before sleep \(delayTime)")
            sleep(UInt32(delayTime))
            print("after sleep \(delayTime)")
            complition()
        }
    }
    
}

public struct Queue<T> {
    fileprivate var array = [T?]()
    fileprivate var head = 0
    
    public var isEmpty: Bool {
        return count == 0
    }
    
    public var count: Int {
        return array.count - head
    }
    
    public mutating func enqueue(_ element: T) {
        array.append(element)
    }
    
    public mutating func dequeue() -> T? {
        guard head < array.count, let element = array[head] else { return nil }
        
        array[head] = nil
        head += 1
        
        let percentage = Double(head)/Double(array.count)
        if array.count > 50 && percentage > 0.25 {
            array.removeFirst(head)
            head = 0
        }
        
        return element
    }
    
    public mutating func removeAll(){
        array.removeAll()
        head = 0
    }
    
    public var front: T? {
        if isEmpty {
            return nil
        } else {
            return array[head]
        }
    }
}

