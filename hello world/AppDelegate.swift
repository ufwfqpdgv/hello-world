//
//  AppDelegate.swift
//  hello world
//
//  Created by lyw on 2018/7/6.
//  Copyright © 2018年 lyw. All rights reserved.
//

import Cocoa

enum interceptKeyEnum {
    case pass
    case next_pass //因如果直接 pass ，最后一字符还是会传到当前激活 app 中
    case stop
}
// interceptKey这个应该都没啥用，写完可以删掉--另外一种快捷键处理用到，暂不管了
var interceptKey = interceptKeyEnum.pass
var startGlobalMotion=false
let charDict = intCharList()
var s=AppDelegate()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    struct markStruct{
        var element: AXUIElement
        var rect : NSRect
    }
    struct elementStruct{
        var element: AXUIElement
        var rect : NSRect
    }
    //这里一定要写外面才 ok，奇了，并跨屏幕也是 ok 的，就写外面吧--双屏横竖通用，nb
    let screenRect=NSScreen.main!.frame
    var elementList:[elementStruct] = []
    var markDict:[String:markStruct]=[:]
    var inputingKey=""
    var applicationAXElement = AXUIElementCreateSystemWide()
    var parentWinCtrol = NSWindowController()

    // 频繁使用的变量
    var elementTemp: CFTypeRef?
    var err=AXError.success
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        s=self
        self.startDealKey()
        
        /*
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown], handler: {event in
            // ctrl+shift+command+a启动
            
            //self.printLog(event.modifierFlags.rawValue)
            self.printLog(event.characters)
            
            if event.modifierFlags.rawValue == 1442059 && event.characters=="\u{01}"{
                self.printLog("开始")
                self.clean()
                self.dealCurrentActiveWindow()
                interceptKey=interceptKeyEnum.stop
                startGlobalMotion=true
                return
            }
            if startGlobalMotion{
                //let charTemp = self.conversionChar(event.characters!)
                let key=Int(bitPattern: event.modifierFlags.rawValue)
                let charTemp = charDict[key]
                self.printLog(charTemp)
                
                guard let char = charTemp else{
                    self.clean()
                    return
                }
                if self.cancel(char) || !self.neededKey(char){
                    self.clean()
                    interceptKey=interceptKeyEnum.next_pass
                    return
                }
                self.dealKey(char)
            }
        })
        */
 
        /*
        NotificationCenter.default.addObserver(self, selector: #selector(getModifier(_:)), name: NSNotification.Name("global_motion"), object: nil)
        */
        
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown,.rightMouseUp], handler: {event in
            self.clean()
            interceptKey=interceptKeyEnum.pass
            //self.dealMouseEvent(event) //被 BAB 拦截掉了，做不了
        })
    }

    var rightMouseDown:Bool=false
    func dealMouseEvent(_ event:NSEvent){
        switch event.type {
        case .rightMouseDown:
            rightMouseDown=true
        case .rightMouseUp:
            rightMouseDown=false
        case .leftMouseDown:
            if rightMouseDown{
                printLog("触发")
                rightMouseDown=false
            }
        default:
            printLog("other")
        }
    }
    
    func conversionChar(_ input:String)->String?{
        switch input {
        case "\u{01}":
            return "a"
        case "\u{02}":
            return "b"
        case "\u{03}":
            return "c"
        case "\u{04}":
            return "d"
        case "\u{05}":
            return "e"
        case "\u{06}":
            return "f"
        case "\u{07}":
            return "g"
        case "\u{08}":
            return "h"
        case "\t":
            return "i"
        case "\n":
            return "j"
        case "\u{0B}":
            return "k"
        case "\u{0C}":
            return "l"
        case "\r":
            return "m"
        case "\u{0E}":
            return "n"
        case "\u{0F}":
            return "o"
        case "\u{10}":
            return "p"
        case "\u{11}":
            return "q"
        case "\u{12}":
            return "r"
        case "\u{13}":
            return "s"
        case "\u{14}":
            return "t"
        case "\u{15}":
            return "u"
        case "\u{16}":
            return "v"
        case "\u{17}":
            return "w"
        case "\u{18}":
            return "x"
        case "\u{19}":
            return "y"
        case "\u{1A}":
            return "z"
        default:
            return input
        }
    }

    /*
    // 监听全局按键，用于启动
    @objc func getModifier(_ noti:Notification) {
        let eventTemp = noti.object as! CGEvent  //异常后这里就就再也接不到消息了
        if eventTemp.timestamp==0{
            clean()
            interceptKey=interceptKeyEnum.pass
            return
        }
        let event=NSEvent(cgEvent: eventTemp)
        
        //bug 这里会崩溃，怎么搞？debug 的时候，所有程序都会崩--在下面startDealKey中                    sleep(1) 也会崩，只有有延迟就崩？事件失效了？--shit,只要一卡就出事，不管是哪个 app 里
        
        // ctrl+shift+command+a启动
        if event?.modifierFlags.rawValue == 1442059 && event?.characters=="\u{01}"{
            printLog("开始")
            clean()
            dealCurrentActiveWindow()
            interceptKey=interceptKeyEnum.stop
            startGlobalMotion=true
            return
        }
        if startGlobalMotion{
            guard let char = event?.characters else{
                clean()
                return
            }
            if self.cancel((event!.characters!)) || !self.neededKey(char){
                clean()
                interceptKey=interceptKeyEnum.next_pass
                return
            }
            dealKey(char)
        }
    }
 */
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // 不传递了，直接在这里处理及转换--这才是能行的，？？？
    func startDealKey(){
        let eventTap:CFMachPort = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: 1 << CGEventType.keyDown.rawValue,
            callback: {(proxy: CGEventTapProxy, type: CGEventType, _event: CGEvent, refcon: UnsafeMutableRawPointer?)->Unmanaged<CGEvent>?  in
                
                // 太久会超时，本CFRunLoopRun会崩，直接重开一个就可以继续用了
                if _event.timestamp==0{
                    s.startDealKey()
                    return nil
                }
                
                guard let event=NSEvent(cgEvent: _event) else{
                    startGlobalMotion=false
                    return nil
                }
                // ctrl+shift+command+a启动
                if event.modifierFlags.rawValue == 1442059 && event.characters=="\u{01}"{
                    s.printLog("开始")
                    s.clean()
                    s.dealCurrentActiveWindow()
                    interceptKey=interceptKeyEnum.stop
                    startGlobalMotion=true
                    return nil
                }
                if startGlobalMotion{
                    guard let char = event.characters else{
                        s.clean()
                        return nil
                    }
                    if s.cancel(char) || !s.neededKey(char){
                        s.clean()
                        interceptKey=interceptKeyEnum.next_pass
                        return nil
                    }
                    s.dealKey(char)
                    return nil
                }
                
                return Unmanaged.passRetained(_event)
        },
            userInfo: nil)!
        
        let runLoopSource:CFRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, CFRunLoopMode.commonModes);
        CGEvent.tapEnable(tap: eventTap, enable: true);
        
        CFRunLoopRun();
    }
    
    /*
     func startDealKey(){
     // 拦截键盘事件，不过好像这个甚至在上面执行之前，难道设个标记啥的让上面先触发 ok 吗，后面再搞
     // 可能通过事件的方式只给自己 app 传事件，其他的都不传，app 结束后再置为给所有人传
     let eventTap:CFMachPort = CGEvent.tapCreate(
     tap: .cghidEventTap,
     place: .headInsertEventTap,
     options: .defaultTap,
     eventsOfInterest: 1 << CGEventType.keyDown.rawValue,
     callback: {(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?)->Unmanaged<CGEvent>?  in
     
     NotificationCenter.default.post(name: NSNotification.Name("global_motion"), object: event)
     switch interceptKey{
     case .pass:
     return Unmanaged.passRetained(event)
     case .next_pass:
     interceptKey = .pass
     return nil
     case .stop:
     return nil
     }
     },
     userInfo: nil)!
     
     let runLoopSource:CFRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
     
     CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, CFRunLoopMode.commonModes);
     CGEvent.tapEnable(tap: eventTap, enable: true);
     
     CFRunLoopRun();
     }
     */
    
    func neededKey(_ char:String)->Bool{
        for (_,v) in charDict{
            if v==char{
                return true
            }
        }
        return false
    }
    
    func cancel(_ char:String)->Bool{
        if char==" " || char=="\u{1B}" || char=="\r"{
            return true
        }
        return false
    }
    
    func dealKey(_ char:String){
        inputingKey+=char
        if (markDict[inputingKey] != nil){
            // 有些元素并没有 press 的 action，故换成模拟鼠标点击--但却一是不准确，二是卡乱要死，三还乱正常鼠标点击，什么鬼--因只发出了Mousedown 事件没发 mouseUp 事件
            let src=CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
            var point=CGPoint()
            point.x=(markDict[inputingKey]?.rect.midX)!
            point.y=(markDict[inputingKey]?.rect.midY)!
            let mouseEvent=CGEvent(mouseEventSource: src, mouseType: CGEventType.leftMouseDown, mouseCursorPosition: point, mouseButton: CGMouseButton.left)
            mouseEvent?.post(tap: CGEventTapLocation.cghidEventTap)
            mouseEvent?.type=CGEventType.leftMouseUp
            mouseEvent?.post(tap: CGEventTapLocation.cghidEventTap)
            clean()
            interceptKey=interceptKeyEnum.next_pass
            
            /*
             err=AXUIElementPerformAction((markDict[inputingKey]?.element)!, "AXPress" as CFString)
             clean()
             interceptKey=interceptKeyEnum.next_pass
             if err != AXError.success{
             printLog(err)
             return
             }
             */
        }
        //如若都没触发
        if inputingKey.count==2{
            clean()
            interceptKey=interceptKeyEnum.next_pass
        }

        let fieldList=parentWinCtrol.window?.contentView?.subviews as? [NSTextField]
        for(key,_) in markDict{
            if !key.hasPrefix(char){
                for field in fieldList!{
                    if field.stringValue==key{
                        field.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    func clean(){
        startGlobalMotion=false
        if markDict.count==0{
            return
        }
        printLog("clean")
        
        parentWinCtrol.close()
        
        markDict=[:]
        elementList = []
        inputingKey=""
    }
 
    func dealCurrentActiveWindow(){
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let privOptions = [trusted: false] as CFDictionary
        //let options : NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)
        if !accessEnabled{
            printLog("申请权限")
            //模态化弹出
            AXIsProcessTrustedWithOptions(privOptions)
        }
        
        let pid=currentActiveAppPid()
        if pid==0{
            printLog("pid is 0")
            return
        }
        applicationAXElement = AXUIElementCreateApplication(pid)
        
        // 标记所有项并存到一 map 中，标记字为 key，应该得遍历的方式，到底结束
        //1、获取所有可选元素
        // 暂只要标准窗口里的，不处理菜单--可能不止一个标准窗口,但取多个又有可能异常，有些隐藏的窗口也会算在这里，故只取第一个
        let standardElementList=findStandardWindow(applicationAXElement)
        if standardElementList==nil{
            printLog("standardElementList nil")
            return
        }
        var appRect = NSRect()
        for element in standardElementList!{
            let (success,appRectTemp)=elementFrame(element)
            if !success{
                return
            }
            printLog(appRectTemp)
            getAllElement(element,appRectTemp!)
            appRect=appRectTemp!
            break
        }
        printLog(elementList.count)
        
        //1.5、制作一父窗口
        let width=appRect.width,height=appRect.height
        let x=appRect.minX
        let y=screenRect.width-appRect.maxY
        let parentWin=NSWindow(contentRect: NSRect(x: x, y: y, width: width, height: height), styleMask: NSWindow.StyleMask.resizable, backing: NSWindow.BackingStoreType.buffered, defer: true)
        parentWin.isOpaque=false
        parentWin.backgroundColor=NSColor.clear 
        parentWin.level=NSWindow.Level.floating
        
        //2、26及以下只用单个词标记，以上根据 /26后的数量，如为3则用 a？ b？ c？ 加 d e f g h i j
        let int=elementList.count/26
        var i=0,j=0
        var intTemp=int
        for e in elementList{
            if elementList.count<=26{
                let key=charDict[j]!
                markElement(e.rect,key,appRect,parentWin)
                markDict[key] = markStruct(element:e.element, rect:e.rect)
                j+=1
            }else{
                //好麻烦，26以上直接先赋值单个的赋值，剩下再用双字母的
                if intTemp != 26{
                    let key=charDict[intTemp]!
                    markElement(e.rect,key,appRect,parentWin)
                    markDict[key] = markStruct(element:e.element,rect:e.rect)
                    intTemp+=1
                }else{
                    let key=charDict[i]!+charDict[j]!
                    markElement(e.rect,key,appRect,parentWin)
                    markDict[key] = markStruct(element:e.element, rect:e.rect)
                    j+=1
                    if j==26{
                        i+=1
                        j=0
                    }
                }
            }
        }
        parentWinCtrol = NSWindowController(window: parentWin)
        parentWinCtrol.showWindow(self)
        
        //3、回头根据全局按键响应相应处理--在顶上
        return
    }
    
    func findStandardWindow(_ element:AXUIElement)->[AXUIElement]?{
        err=AXUIElementCopyAttributeValue(element, "AXChildren" as CFString, &elementTemp)
        if err != AXError.success{
            printLog(err)
            return nil
        }
        
        var elementList=[AXUIElement]()
        let childrenList=elementTemp as! [AXUIElement]
        for item in childrenList{
            if standardWindow(item){
                elementList += [item]
            }
        }
        if elementList.count==0{
            return nil
        }else{
            return elementList
        }
    }
    
    // 过滤条件得改成取想要的类型，如 button，cell
    func getAllElement(_ element:AXUIElement,_ appRect:NSRect){
        let (need1,_)=neededElementType(element)
        let (need2,rect)=onScreen(element,appRect)
 
        if !need2{
            return
        }
        
        if need1 && need2{
            elementList.append(elementStruct(element:element, rect: rect!))
            return
        }else{
            err=AXUIElementCopyAttributeValue(element, "AXChildren" as CFString, &elementTemp)
            if err != AXError.success{
                //printLog(err)
                return
            }
            let childrenList=elementTemp as! [AXUIElement]
            for item in childrenList{
                getAllElement(item,appRect)
            }
        }
    }
    
    let vs=["AXStaticText","AXImage","AXButton","AXTextArea","AXCheckBox",
            "AXMenuButton","AXPopUpButton","AXMenuItem","AXSlider","AXRadioButton",
            "AXCell","AXTextField","AXDisclosureTriangle"]
    func neededElementType(_ element:AXUIElement)->(Bool,String){
        err=AXUIElementCopyAttributeValue(element, "AXRole" as CFString, &elementTemp)
        if err == AXError.success{
            let s=elementTemp as! String
            for v in vs{
                if v==s{
                    return (true,s)
                }
            }
        }
        return (false,"")
    }
    
    // 显示在当前激活窗口范围内才要--得细致到只在父窗口内，不然还是会显示多余（暂显示不错了，滚动条相关有些难处理，不影响使用）--多余些没问题吧，要用的都能标记到就好
    func onScreen(_ element:AXUIElement,_ appRect:NSRect)->(Bool,NSRect?){
        let (success,rect)=elementFrame(element)
        if !success{
            return (success,nil)
        }
        
        // 判定还是有些问题，有些应该标记的窗口没标记上，xcode 的编辑框
        if (appRect.minX.isLessThanOrEqualTo((rect?.minX)!)) &&
            (rect?.minX.isLessThanOrEqualTo((appRect.maxX)))! &&
            //(appRect.minY.isLessThanOrEqualTo((rect?.minY)!)) && //这个会导致滚动往下之后整个列表标记不到
            (rect?.minY.isLessThanOrEqualTo((appRect.maxY)))! {
            return (true,rect)
        }else{
            printLog(rect)

            return (false,nil)
        }
    }
    
    func elementFrame(_ element:AXUIElement)->(Bool,NSRect?){
        err=AXUIElementCopyAttributeValue(element, "AXFrame" as CFString, &elementTemp)
        if err != AXError.success{
            printLog(err)
            return (false,nil)
        }
        let axValue=elementTemp as! AXValue
        var rect=NSRect.zero
        AXValueGetValue(axValue, AXValueType.cgRect, &rect)
        return (true,rect)
    }
    
    func standardWindow(_ element:AXUIElement)->Bool{
        err=AXUIElementCopyAttributeValue(element, "AXRole" as CFString, &elementTemp)
        if err == AXError.success{
            let s=elementTemp as! String
            if s=="AXWindow"{
                return true
            }
        }
        return false
    }
    
    func markElement(_ rect:NSRect,_ key:String,_ appRect:NSRect,_ parentWin:NSWindow){
        
        let width=CGFloat(30.0),height=CGFloat(20.0)
        let x=(rect.midX-appRect.minX)-width/2
        let y=appRect.maxY-rect.midY-height/2
        /* // 暂只是测试，把标记设为整块
         let x=rect.minX
         let y=screenRect.width-rect.maxY
         */
        let field=NSTextField(frame: NSRect(x: x, y: y, width: width, height: height))
        field.backgroundColor=NSColor(calibratedRed: 1, green: 1, blue: 0, alpha: 0.6)
        field.isEditable=false
        field.isBezeled=false
        field.stringValue=key
        field.font=NSFont(name: "Monaco", size: 15.0)
        field.alignment=NSTextAlignment.center

        parentWin.contentView?.addSubview(field)
    }

    func debugAttribute(_ element:AXUIElement){
        var elementTemp: CFTypeRef?
        let vs=["AXTitle","AXHelp","AXRole","AXRoleDescription","AXDescription","AXFrame"]
        for v in vs{
            let err=AXUIElementCopyAttributeValue(element, v as CFString, &elementTemp)
            if err == AXError.success{
                printLog(v)
                printLog(elementTemp)
            }
        }
        print("\n")
    }
    
    func debugAttributeNames(_ element:AXUIElement){
        let valueList=UnsafeMutablePointer<CFArray?>.allocate(capacity: 999)
        var err=AXUIElementCopyAttributeNames(element,valueList)
        if err != AXError.success{
            printLog(err)
            return
        }
        printLog("attributeNames:")
        printLog(valueList.pointee)
        
        err=AXUIElementCopyActionNames(element, valueList)
        if err != AXError.success{
            printLog(err)
            return
        }
        printLog("actionNames:")
        printLog(valueList.pointee)
    }
    
    func printLog<T>(_ message: T,
                     file: String = #file,
                     method: String = #function,
                     line: Int = #line)
    {
        //print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
        //print("\(method)[\(line)]: \(message)")
        print("[\(line)]: \(message)")
    }
    
    func currentActiveAppPid()->pid_t{
        let myAppleScript = "tell application \"System Events\"\n" +
            " get unix id of first application process whose frontmost is true\n" +
        " end tell"
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: myAppleScript) {
            if let output: NSAppleEventDescriptor =
                scriptObject.executeAndReturnError(&error) {
                return output.int32Value
            } else if (error != nil) {
                printLog("error: \(String(describing: error))")
                return 0
            }
        }
        return 0
    }
}

func intCharList()->[Int:String]{
    let charDict:[Int:String]=[0:"a",
                               1:"b",
                               2:"c",
                               3:"d",
                               4:"e",
                               5:"f",
                               6:"g",
                               7:"h",
                               8:"i",
                               9:"j",
                               10:"k",
                               11:"l",
                               12:"m",
                               13:"n",
                               14:"o",
                               15:"p",
                               16:"q",
                               17:"r",
                               18:"s",
                               19:"t",
                               20:"u",
                               21:"v",
                               22:"w",
                               23:"x",
                               24:"y",
                               25:"z",
                               ]
    return charDict
}
