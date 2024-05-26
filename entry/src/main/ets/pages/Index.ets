import {createTable, insertData, queryData} from './DBManager'
import systemDateTime from '@ohos.systemDateTime';
import display from '@ohos.display'

@Entry
@Component
struct Home {
  private controller_tabs : TabsController = new TabsController()
  //private controller_dialog: CustomDialogController = new CustomDialogController()
  private displayClass: display.Display | null = null
  private dpi: number = 160

  @State list: Array<any> = []
  @State gridData: any[6] = []

  @State page: number = 1
  private pageSize: number = 20

  // 测试用数据
  private testData: any[6] = [
    {"deviceID": 0, "value": 50, "status": 0},
    {"deviceID": 1, "value": 50, "status": 0},
    {"deviceID": 2, "value": 50, "status": 0},
    {"deviceID": 3, "value": 50, "status": 0},
    {"deviceID": 4, "value": 50, "status": 0},
    {"deviceID": 5, "value": 50, "status": 0},
  ]
  private gridArr: string[] = ['烟雾传感器', '火焰传感器', '温度传感器', '湿度传感器', '舵机', '蜂鸣器']

  aboutToAppear() {
    this.init()
    console.log(this.page.toString())
  }

  init() {
    // 获得屏幕信息
    try {
      this.displayClass = display.getDefaultDisplaySync();
      this.dpi = this.displayClass.densityDPI
      console.log('Test densityDPI:' + JSON.stringify(this.displayClass.densityDPI));
    } catch (exception) {
      console.error('Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
    }
    // 数据初始化
    createTable(getContext(this))
    this.query()
    this.update()
    // 启动定时器
    setInterval(this.update.bind(this), 3000)
  }
  update() {
    for(let i = 0; i < 6; i++){
      const randNum = getRandomNumber(1, 103)
      const lv = Math.floor((randNum - 88) / 4)
      this.testData[i].value = randNum
      if(lv < 1) this.testData[i].status = 0
      else{
        this.testData[i].value = randNum
        this.testData[i].status = 1
        getTimeString().then(time => {
          const item = {
            date: time,
            level: `${lv}`,
            info: `${this.gridArr[i]}发出${lv}级警报！` }
          insertData(getContext(this), item).then(res => {
            console.log(`update: ${JSON.stringify(item)}`)
            if(res) this.list.unshift(item)
            else console.log(`update error`)
          })
        })
      }
    }
    this.gridData.clear
    this.gridData = this.testData
  }
  addData() {
    for(let i = 0; i < 20; i++){
      getTimeString().then(time => {
        let level = getRandomNumber(1, 3)
        const item = {
          date: time,
          level: `${level}`,
          info: `${this.gridArr[getRandomNumber(0, 5)]}发出${level}级警报！` }
        insertData(getContext(this), item).then(res => {
          this.query()
        })
      })
    }
  }
  query() {
    queryData(getContext(this), this.page, this.pageSize)
      .then(data => {
        if(data){
          if(this.page == 1)
            this.list = data
          else
            this.list = this.list.concat(data)
          this.page++
        }
        else {
          console.log('now last page')
        }
      })
  }

  @Builder buildLogList() {
    Row() {
      this.buildLogo()
      if(this.list.length != 0) {
        List({space: 20, initialIndex: 0}) {
          ForEach(this.list, (item) => {
            ListItem() {
              Row(){
                // 警告等级数字
                Text(item.level)
                  .width('30%')
                  .fontSize(this.dpi / 2.5)
                  .fontColor(getTextColor(Number(item.level)))
                  .textAlign(TextAlign.Center)
                // 警告内容
                Column(){
                  Text(item.date)
                    .fontSize(this.dpi / 5)
                    .fontColor(Color.Black)
                    .textAlign(TextAlign.Center)
                    .padding({bottom: 5})
                  Text(item.info)
                    .fontSize(this.dpi / 4)
                    .maxLines(2)
                    .textOverflow({overflow:TextOverflow.Ellipsis})
                }
                .width('70%')
                .padding({right:'5%'})
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Start)
              }
              .height('20%')
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#f5f5f5')
              .borderRadius(10)
            }.editable(true)
          })
        }
        .width('60%')
        .height('80%')
        //.divider({strokeWidth:1, color:Color.Grey, startMargin:20, endMargin:20})
        .onReachEnd( () => {
          console.log(`now page ${this.page}`)
          this.query()
        })
      }
      else {
        Text('empty')
          .fontColor('#708090')
          .fontSize(this.dpi / 4)
          .textAlign(TextAlign.Center)
          .height('80%')
          .width('60%')
      }
    }
  }
  @Builder buildGrid() {
    Row() {
      this.buildLogo()
      Grid(){
        ForEach(this.gridData, (item, index) => {
          GridItem(){
            Column(){
              Text(`${this.gridArr[item.deviceID]}`)
                .fontSize(this.dpi / 5)
                .fontColor(Color.Black)
                .textAlign(TextAlign.Center)
                .padding({top: '3%'})
                .height('30%')

              Column(){
                // 火焰传感器 & 烟雾传感器
                if(index == 0 || index == 1) {
                  // 状态显示
                  Text(`${getStatusText(item.status)}`)
                    .fontColor(getStatusColor(item.status))
                    .fontSize(this.dpi / 4)
                    .fontWeight(FontWeight.Bold)
                    .padding({top: '3%'})
                  // 数据显示
                  Text(String(item.value))
                    .fontSize(this.dpi / 4)
                    .fontColor(getStatusColor(item.status))
                    .padding({top: '2%'})
                }
                // 温湿度传感器
                else if(index == 2 || index == 3) {
                  if(index == 2) {
                    Text(`${item.value}°C`)
                      .fontSize(this.dpi / 3)
                      .fontColor('#708090')
                      .padding('5%')
                  }
                  else {
                    Text(`${item.value}%`)
                      .fontSize(this.dpi / 3)
                      .fontColor('#708090')
                      .padding('5%')
                  }
                }
                // 舵机 & 蜂鸣器
                else {
                  // 状态显示
                  Text(`${getStatusText(item.status)}`)
                    .fontColor(getStatusColor(item.status))
                    .fontSize(this.dpi / 3)
                    .fontWeight(FontWeight.Bold)
                    .padding({top: '3%'})
                }
              }
              .height('65%')
            }
            .height('100%')
            .width('100%')
            .backgroundColor('#f7f7f7')
            .borderRadius(10)
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .height('80%')
      .width('60%')
    }
    .backgroundColor(Color.White)
  }
  @Builder buildLogo() {
    Column(){
      Column(){
        // 标题
        Text('OpenHarmony')
          .fontColor(Color.Blue)
          .fontSize(this.dpi / 2)
          .fontStyle(FontStyle.Italic)
          .fontWeight(FontWeight.Bold)
          .fontFamily('Arial')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({top:'30%'})
          .margin({bottom:10})

        Text('智能消防系统')
          .fontColor(Color.Black)
          .fontSize(this.dpi / 2)
          .fontFamily('SimHei')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding( {bottom: '20%'} )
      }
      .width('90%')
      .height('80%')
      .backgroundColor('#f5f5f5')
      .borderRadius(10)
    }
    .width('40%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
  }
  @Builder buildHomePage() {
    Row(){
      this.buildLogo()
      Column(){
        Column(){
          Text('消防监控系统目前')
            .fontColor(Color.Black)
            .fontSize(this.dpi / 4)
            .textAlign(TextAlign.Center)
          Text('正常')
            .fontColor(Color.Green)
            .fontSize(this.dpi / 2)
            .fontWeight(FontWeight.Bold)
            .padding({top: '5%'})
        }
        .backgroundColor('#98ff98')
        .width('90%')
        .height('50%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(10)
        .margin( {top: '2%'} )
        // 报警按钮
        Button('一键报警', { type: ButtonType.Normal, stateEffect: true })
          .onClick(() => {
            // 报警弹窗
          })
          .width('90%')
          .height('35%')
          .fontSize(this.dpi / 3)
          .fontColor(Color.Red)
          .backgroundColor(Color.Yellow)
          .borderRadius(10)
          .margin( {top: '5%'} )
      }
      .width('60%')
      .height('80%')
      .alignItems(HorizontalAlign.Center)
    }
    .backgroundColor(Color.White)
  }

  build() {
    Column(){

      // 导航栏组件
      Tabs({ barPosition: BarPosition.End, controller: this.controller_tabs }){
        // 首页
        TabContent(){
          this.buildHomePage()
        }
        .tabBar('首页')

        // 消防页面
        TabContent(){
          Column(){
            this.buildGrid()
          }
        }
        .tabBar('消防')

        // 日志页面
        TabContent(){
          Column(){
            // 日志信息列表
            this.buildLogList()
          }
          .backgroundColor(Color.White)
          .width('100%')
          .height('100%')
        }
        .tabBar('日志')
      }
      .barWidth('100%')
      .barHeight('15%')
      .width('100%')
      .height('100%')
      .backgroundColor(0xF5F5F5)
      .vertical(false)
    }
  }
}

function getTextColor(x: number){
  if(x == 3)
    return Color.Red
  if(x == 2)
    return Color.Orange

  return Color.Yellow
}

function getStatusText(x: number){
  if(x == 1) return '异常'
  if(x == 0) return '正常'
}

function getStatusColor(x: number){
  if(x == 1) return Color.Red
  if(x == 0) return Color.Green
}

function getRandomNumber(minNum: number, maxNum: number): number{
  return Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum;
}

function getTimeString(): any {
  const promise = systemDateTime.getCurrentTime(false)
  return promise.then(timestamp => {
    //timestamp += getRandomNumber(1000000000, 5000000000)     // 测试用随机数
    const currentTime: Date = new Date(timestamp);
    const year: number = currentTime.getFullYear();
    const month: number = currentTime.getMonth() + 1; // 月份从0开始，需要加1
    const day: number = currentTime.getDate();
    const hours: number = currentTime.getHours();
    const minutes: number = currentTime.getMinutes();
    const seconds: number = currentTime.getSeconds();

    // 将数字转换为两位数的字符串形式（补0）
    const padZero = (num: number): string => {
      return num < 10 ? '0' + num : num.toString()
    }

    // 构建字符串
    const formattedTime: string = `${year}-${padZero(month)}-${padZero(day)} ${padZero(hours)}:${padZero(minutes)}:${padZero(seconds)}`;
    return formattedTime
  }).catch(err => {
    throw err
  })
}