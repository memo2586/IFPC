import {createTable, insertData, queryData} from './DBManager'
import systemDateTime from '@ohos.systemDateTime';
import display from '@ohos.display'
// @ts-ignore
import i2cnapidemo from '@ohos.i2cnapidemo';
// @ts-ignore
import adc_napi from '@ohos.adc_napi';
// @ts-ignore
import pwmtest from '@ohos.pwmtest';
import prompt from '@ohos.prompt';

@Entry
@Component
struct Home {

  @State pwm1_start :boolean = false
  @State pwm2_start :boolean = false
  @State flameSensorThreshold: number = 10
  @State smokeSensorThreshold: number = 10

  private controller_tabs : TabsController = new TabsController()
  private controller_dialog1: CustomDialogController = new CustomDialogController({
    builder: CustomDialogValueInput({
      textValue: this.flameSensorThreshold,
      inputValue: $flameSensorThreshold,
    })
  })
  private controller_dialog2: CustomDialogController = new CustomDialogController({
    builder: CustomDialogValueInput({
      textValue: this.smokeSensorThreshold,
      inputValue: $smokeSensorThreshold,
    })
  })
  private displayClass: display.Display | null = null
  private dpi: number = 160

  @State list: Array<any> = []
  @State gridData: any[6] = []
  @State page: number = 1
  private pageSize: number = 20
  private indexOffset: number = 0

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

    // 循环处理六个网格的数据
    for (let i = 0; i < 6; i++) {
      const randNum = getRandomNumber(1, 103);
      this.testData[i].value = randNum;

      // 获取温度、湿度
      const sensorData = readTemperatureAndHumidity();
      if(sensorData!=null){
        // 温度
        if(i==2){
          this.testData[i].value = sensorData.temperatureC.toFixed(3);
        }
        // 湿度
        if(i==3){
          this.testData[i].value = sensorData.humidity.toFixed(3);
        }
      }
      // 获取ppm(烟雾浓度)
      const ppmValue_f = getPPMValue();

      if(ppmValue_f){
        const ppmValue = ppmValue_f.toFixed(3)
        // 烟雾浓度
        if(i==0){
          this.testData[i].value = ppmValue;
        }
      }

      // 获取火焰传感器 adc值
      const fireValue_f = getFIREValue();
      if(fireValue_f){
        const fireValue = fireValue_f.toFixed(3)
        // 火焰adc
        if(i==1){
          this.testData[i].value = fireValue;
        }
      }

      // 计算警报等级
      const lv = Math.floor((randNum - 88) / 4);

      // 如果警报等级小于1，将状态设为0
      if (lv < 1) {
        this.testData[i].status = 0;
      } else {
        // 否则，设置状态为1，并获取时间字符串
        this.testData[i].value = randNum;
        this.testData[i].status = 1;
        getTimeString().then(time => {
          // 构造警报信息对象
          const item = {
            date: time,
            level: `${lv}`,
            info: `${this.gridArr[i]}发出${lv}级警报！`
          };
          // 插入数据并在插入成功后更新列表
          insertData(getContext(this), item).then(res => {
            console.log(`update: ${JSON.stringify(item)}`);
            this.indexOffset++
            if (res) this.list.unshift(item)
            else console.log(`update error`)
          });
        });
      }
    }

    this.gridData = this.testData;
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
    queryData(getContext(this), this.page, this.indexOffset, this.pageSize)
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
                  Row() {
                    Stack() {
                      Row() {
                        Column() {
                          // 状态显示
                          Text(`${getStatusText(item.status)}`)
                            .fontColor(getStatusColor(item.status))
                            .fontSize(this.dpi / 4)
                            .fontWeight(FontWeight.Bold)
                          // 数据显示
                          Text(String(item.value))
                            .fontSize(this.dpi / 4)
                            .fontColor(getStatusColor(item.status))
                            .padding({top: '2%'})
                        }
                      }
                      .width('100%')
                      .justifyContent(FlexAlign.Center)

                      Row() {
                        Button({ type: ButtonType.Circle, stateEffect: false })
                          .height(this.dpi / 4).width(this.dpi / 4)
                          .backgroundColor('#00000000')
                          .backgroundImage($r('app.media.ic_public_settings'))
                          .backgroundImageSize({ width: '100%', height: '100%' })
                          .onClick((isClick) => {
                            // 弹窗
                            if(index == 1) this.controller_dialog1.open()
                            else this.controller_dialog2.open()
                          })
                      }
                      .width('80%')
                      .justifyContent(FlexAlign.End)
                    }
                  }
                  .width('100%')
                  .padding({top: '3%'})
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
                // 舵机
                else if(index == 4){
                  Row() {
                    Stack() {
                      // 状态显示
                      Row() {
                        Text(`${getStatusText(item.status)}`)
                          .fontColor(getStatusColor(item.status))
                          .fontSize(this.dpi / 3)
                          .fontWeight(FontWeight.Bold)
                          .textAlign(TextAlign.Center)
                      }
                      .width('100%')
                      .justifyContent(FlexAlign.Center)

                      // 舵机开关
                      Row() {
                        Toggle({ type: ToggleType.Switch, isOn: this.pwm1_start })
                          .size({ width: '35%', height: '35%' })
                          .onChange((isChecked) => {
                            this.pwm1_start = !this.pwm1_start
                            if(isChecked) {
                              prompt.showToast({
                                message: "打开舵机", // 显示文本
                              })
                              try {
                                // pwmtest.setPwmStatus(1, 90)
                                console.log(`setPwmStatus ${isChecked}}`)
                              }catch(err) {
                                console.log('ERROR: setPwmStatus failed' + err)
                              }
                            }
                            else {
                              prompt.showToast({
                                message: "关闭舵机", // 显示文本
                              })
                              try {
                                // pwmtest.setPwmStatus(1, 0)
                                console.log(`setPwmStatus ${isChecked}}`)
                              }catch(err) {
                                console.log('ERROR: setPwmStatus failed' + err)
                              }
                            }
                          })
                      }
                      .width('100%')
                      .justifyContent(FlexAlign.End)
                    }
                  }
                  .width('100%')
                  .padding({ top: '3%' })
                }
                else if(index == 5){
                  Row() {
                    Stack() {
                      // 状态显示
                      Row() {
                        Text(`${getStatusText(item.status)}`)
                          .fontColor(getStatusColor(item.status))
                          .fontSize(this.dpi / 3)
                          .fontWeight(FontWeight.Bold)
                          .textAlign(TextAlign.Center)
                      }
                      .width('100%')
                      .justifyContent(FlexAlign.Center)

                      // 蜂鸣器开关
                      Row() {
                        Toggle({ type: ToggleType.Switch, isOn: this.pwm2_start })
                          .size({ width: '35%', height: '35%' })
                          .onChange((isChecked) => {
                            this.pwm2_start = !this.pwm2_start
                            if(isChecked) {
                              prompt.showToast({
                                message: "打开蜂鸣器",
                              })
                              try {
                                // pwmtest.setPwmStatus(2, 90)
                                console.log(`setPwmStatus ${isChecked}}`)
                              }catch(err) {
                                console.log('ERROR: setPwmStatus failed' + err)
                              }
                            }
                            else {
                              prompt.showToast({
                                message: "关闭蜂鸣器",
                              })
                              try {
                                // pwmtest.setPwmStatus(2, -90)
                                console.log(`setPwmStatus ${isChecked}}`)
                              }catch(err) {
                                console.log('ERROR: setPwmStatus failed' + err)
                              }
                            }
                          })
                      }
                      .width('100%')
                      .justifyContent(FlexAlign.End)
                    }
                  }
                  .width('100%')
                  .padding({ top: '3%' })
                }
              }
              .height('65%').width('100%')
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

@CustomDialog
struct CustomDialogValueInput {
  @Link inputValue: number
  private textValue: number
  controller?: CustomDialogController

  build() {
    Column() {
      Text('更新警报阈值：').fontSize(20).margin({ top: 10, bottom: 10 })
      TextInput({ placeholder: '', text: this.inputValue.toString() }).height(60).width('90%')
        .type(InputType.Number)
        .onChange((value: string) => {
          this.textValue = Number(value)
        })
      Text('是否确认修改?').fontSize(16).margin({ bottom: 10 }).padding({top: 20})
      Flex({ justifyContent: FlexAlign.SpaceAround }) {
        Button('取消')
          .onClick(() => {
            this.controller.close()
          }).backgroundColor(0xffffff).fontColor(Color.Black)
        Button('确认')
          .onClick(() => {
            if (this.controller != undefined) {
              this.inputValue = this.textValue
              this.controller.close()
              prompt.showToast({
                message: `成功更新警报阈值为${this.inputValue}`,
              })
            }
          }).backgroundColor(0xffffff).fontColor(Color.Red)
      }.margin({ bottom: 10 })
    }.borderRadius(10)
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
function getRandomNumber(minNum: number, maxNum: number): number{
  return Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum;
}

// 函数：读取温湿度数据
function readTemperatureAndHumidity() {
  // 调用传感器软重启函数
  const softResetResult = i2cnapidemo.SoftReset();
  console.log('Sensor Soft Reset Result:', softResetResult);

  // 设置传感器测量模式
  const mps = 2; // 2Hz
  const repeatability = 1; // 中刷新率
  const modeSetResult = i2cnapidemo.ModeSet(mps, repeatability);
  console.log('Sensor Mode Set Result:', modeSetResult);

  // 读取温湿度数据
  const readDataResult = i2cnapidemo.ReadData();
  console.log('Read Data Result:', readDataResult);

  // 使用下列三个接口时必须先调用ReadData
  if (readDataResult === 0) {
    // 读取摄氏温度
    const temperatureC = i2cnapidemo.ReadTemperatureC();

    // 读取华氏温度
    const temperatureF = i2cnapidemo.ReadTemperatureF();

    // 读取湿度
    const humidity = i2cnapidemo.ReadHumidity();

    return {
      temperatureC,
      temperatureF,
      humidity
    };
  } else {
    console.log('Failed to read data. Please check the sensor connection and try again.');
    return null;
  }
}
function getPPMValue() {
  // 获取 ADC 值
  let adcValue = 20
  try {
    adcValue = adc_napi.sync_get_adc_value1();
  }catch (err) {
    console.log('ERROR: sync_get_adc_value1 failed.');
    return false
  }

  // 检查是否需要权限
  if (adcValue < 0) {
    let permissionGranted = adc_napi.sync_get_permission1();

    // 检查权限获取结果
    if (!permissionGranted) {
      console.error("无法获取 ADC 值并且权限获取失败");
      return null; // 返回 null 表示无法获取 ppm 值
    }

    // 再次尝试获取 ADC 值
    try {
      adcValue = adc_napi.sync_get_adc_value1();
    }catch (err) {
      console.log('ERROR: sync_get_adc_value1 failed.');
      return false
    }

    // 检查是否成功获取 ADC 值
    if (adcValue < 0) {
      console.error("无法获取 ADC 值");
      return null; // 返回 null 表示无法获取 ppm 值
    }
  }

  // 计算电压值（伏特）
  let voltage = adcValue * (3.3 / 4096);

  // 使用特定的公式将电压转换为 ppm 值
  // 这里使用一个简单的示例，实际上应该根据传感器的特性来计算 ppm 值
  let ppmValue = voltage * 1; // 假设一个简单的线性关系

  return ppmValue;
}
function getFIREValue() {
  // 获取 ADC 值
  let adcValue = 20
  try {
    adcValue = adc_napi.sync_get_adc_value1();
  }catch (err) {
    console.log('ERROR: sync_get_adc_value1 failed.');
    return false
  }

  // 检查是否需要权限
  if (adcValue < 0) {
    let permissionGranted = adc_napi.sync_get_permission2();

    // 检查权限获取结果
    if (!permissionGranted) {
      console.error("无法获取 ADC 值并且权限获取失败");
      return null; // 返回 null 表示无法获取 ppm 值
    }

    // 再次尝试获取 ADC 值
    try {
      adcValue = adc_napi.sync_get_adc_value1();
    }catch (err) {
      console.log('ERROR: sync_get_adc_value1 failed.');
      return false
    }

    // 检查是否成功获取 ADC 值
    if (adcValue < 0) {
      console.error("无法获取 ADC 值");
      return null; // 返回 null 表示无法获取 fire 值
    }
  }

  // 计算电压值（伏特）
  let voltage = adcValue * (3.3 / 4096);

  // 使用特定的公式将电压转换为 fire 值
  // 这里使用一个简单的示例，实际上应该根据传感器的特性来计算 fire 值
  let fireValue = voltage * 1; // 假设一个简单的线性关系

  return fireValue;
}