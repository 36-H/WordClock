import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import emitter from '@ohos.events.emitter';
import { AnswerStatus } from '../enums/AnswerStatus'
import { OptionStatus } from '../enums/OptionStatus'
import { PracticeStatus } from '../enums/PracticeStatus'
import { createPost } from '../http/Api';
import { getRandomQuestions, Question } from '../model/Question'
import { convertMillisecondsToTime } from '../utils/DateUtil';
@Entry
@Component
export struct AnswerPage {
  @State message: string = 'Hello World'

  //存储本轮测试已答题目的数量
  @State answeredCount:number =0

  //存储本轮测试中答题正确的个数
  @State rightCount:number = 0

  //定义一个状态变量保存题目个数
  @State totalCount: number = 10

  //定义一个状态变量保存题目数据,数组
  @State questions: Question[] = getRandomQuestions(this.totalCount)

  //定义一个状态变量，存储当前页面处于什么练习状态
  @State practiceStatus: PracticeStatus = PracticeStatus.Stopped

  //创建一个用于控制计时器的控制器
  timerController: TextTimerController = new TextTimerController();

  //存储所用时间
  timeUsed:number = 0

  //定义一个状态变量用于保存当前题目的索引
  @State currentIndex: number = 0

  //定义一个状态变量answerStatus，存储当前这道题目答题状态
  @State answerStatus:AnswerStatus = AnswerStatus.Answering

  //定义一个状态变量selectedOption，用于存储当前用户选择的题目的答案项
  @State selectedOption:string = ''

  //初始化一个控制打卡弹窗的控制器
  dialogController:CustomDialogController = new CustomDialogController({
    builder: ResultDialog({
      answeredCount: this.answeredCount,
      rightCount: this.rightCount,
      timeUsed: this.timeUsed,
      //点击再测一次按钮
      resetPractice: () => {
        this.questions = getRandomQuestions(this.totalCount)
        this.currentIndex = 0
        this.answeredCount = 0
        this.rightCount = 0
        this.timeUsed = 0
        this.timerController.reset()
        this.answerStatus = AnswerStatus.Answering
      },
      startPractice: () => {
        this.practiceStatus = PracticeStatus.Running
        // 启动计时器
        this.timerController.start()
      }
    }),
    customStyle: true,
    autoCancel: false
  })

  build() {
    Column() {
      //统计面板区域
      Column() {
        //题目个数
        Row() {
          StatItem({
            icon: $r('app.media.ic_count'),
            name: '个数',
            fontColor: Color.Black
          }) {
            //填充占位符的部分的内容
            Button(this.totalCount.toString())
              .width(100)
              .height(25)
              .backgroundColor('#ffddd7d7')
              .fontColor(Color.Black)
              .enabled(this.practiceStatus === PracticeStatus.Stopped) //在停止答题的状态下，按钮才可被点击
              .onClick(() => {
                //打开文本选择器弹窗，用于选择单词个数
                TextPickerDialog.show({
                  range: ['5', '10', '15', '20'],
                  value: this.totalCount.toString(),
                  onAccept: (result) => {
                    this.totalCount = parseInt(result.value)
                    //重新生成对应数量的题目，更新题目数组
                    this.questions = getRandomQuestions(this.totalCount)
                  }
                })
              })
          }
        }
        //进度
        Row() {
          StatItem({
            icon: $r('app.media.ic_progress'),
            name: '进度',
            fontColor: Color.Black
          }) {
            //填充占位符的部分的内容
            Progress({ value: this.answeredCount, total: this.totalCount })
              .width(100)
          }
        }
        Row(){
          StatItem({
            icon: $r('app.media.ic_accuracy'),
            name: '准确率',
            fontColor: Color.Black
          }) {
            //填充占位符的部分的内容
            Text((this.rightCount === 0? 0: this.rightCount/this.answeredCount*100).toFixed()+'%')
              .width(100)
              .textAlign(TextAlign.Center)
          }
        }
        //用时
        Row() {
          StatItem({
            icon: $r('app.media.ic_timer'),
            name: '用时',
            fontColor: Color.Black
          }) {
            //填充占位符的部分的内容
            TextTimer({ controller: this.timerController })
              .onTimer((utc,elaspsedTime)=>{
                this.timeUsed = elaspsedTime
              })
          }
        }
      }
      .backgroundColor(Color.White)
      .width('90%')
      .borderRadius(10)
      .padding(20)

      //单词例句展示区域
      Column() {
        Text(this.questions[this.currentIndex].word)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)

        Text(this.questions[this.currentIndex].sentence)
          .fontSize(16)
          .fontColor('#ff969494')
          .fontWeight(FontWeight.Medium)
          .height(40)
          .textAlign(TextAlign.Center)
      }

      //答案选项区域
      Column({ space: 10 }) {
        //循环遍历当前题目的选项的数组，生成每一个选项的按钮
        ForEach(this.questions[this.currentIndex].options, (option) => {
          optionButtonItem({
            option: option,
            answer: this.questions[this.currentIndex].answer,
            selectedOption: this.selectedOption,
            answerStatus: this.answerStatus
          })
            .onClick(() => {
              //判断练习状态，是否开始测试
              if (this.practiceStatus !== PracticeStatus.Running) {
                promptAction.showToast({ message: '请先点击开始测试' })
                return
              }

              //记录选择的选项
              this.selectedOption = option

              //切换这道题的答题状态
              this.answerStatus = AnswerStatus.Answered

              //更新统计信息，更新已答题目的数量answeredCount和答对题目的数量
              this.answeredCount++
              if(option===this.questions[this.currentIndex].answer)
              {
                this.rightCount++
              }

              //切换题目：修改this.currentIndex变量
              if (this.currentIndex < this.questions.length - 1) {
                //没切换到最后一题，继续切换题目
                setTimeout(() => {
                  this.currentIndex++
                  this.answerStatus = AnswerStatus.Answering
                  this.selectedOption = ''
                }, 500)
              }
              else {
                //已经切换到最后一题，此时结束测试，停止计时器，切换答题状态
                this.timerController.pause();
                this.practiceStatus = PracticeStatus.Stopped
                //打开打卡弹窗
                this.dialogController.open()
              }
            })
        },
          (option) => {
            return this.questions[this.currentIndex].word + "-" + option
          }
        )
      }

      //控制按钮区域
      Row({ space: 50 }) {
        //结束测试按钮
        Button('结束测试').controlButtonStyle({
          bg: Color.Transparent,
          border: this.practiceStatus === PracticeStatus.Stopped ? Color.Gray : Color.Black,
          font: this.practiceStatus === PracticeStatus.Stopped ? Color.Gray : Color.Black
        })
          .enabled(this.practiceStatus !== PracticeStatus.Stopped)
          .onClick(() => {
            //停止计时器
            this.timerController.pause();
            //切换练习状态
            this.practiceStatus = PracticeStatus.Stopped
            //打开弹窗
            this.dialogController.open()
          })


        //开始测试按钮
        Button(this.practiceStatus === PracticeStatus.Running ? '暂停测试' : '开始测试').controlButtonStyle({
          bg: this.practiceStatus === PracticeStatus.Running ? '#555555' : Color.Black,
          border: this.practiceStatus === PracticeStatus.Running ? '#555555' : Color.Black,
          font: Color.White
        })
          .stateEffect(false)
          .onClick(() => {
            if (this.practiceStatus === PracticeStatus.Running) {
              //切换状态
              this.practiceStatus = PracticeStatus.Paused

              //暂停计时器
              this.timerController.pause()
            }
            else {
              //切换状态
              this.practiceStatus = PracticeStatus.Running

              //开始计时器
              this.timerController.start()
            }
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundImage($r('app.media.img_practice_bg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .justifyContent(FlexAlign.SpaceEvenly)
    .alignItems(HorizontalAlign.Center)
  }
}


//统计面板的子组件
@Component
export struct StatItem {
  icon: Resource
  name: string
  fontColor: Color
  //占位符
  @BuilderParam statComp: () => void;

  build() {
    Row({ space: 10 }) {

      Image(this.icon)
        .height(14)
        .width(14)

      Text(this.name)
        .fontWeight(FontWeight.Medium)
        .fontSize(14)
        .fontColor(this.fontColor)

      Blank()

      //调用占位符，占据空白空间
      this.statComp()
    }
    .width('100%')
    .height(30)
  }
}

//选项按钮的子组件
@Component
struct optionButtonItem {
  option: string
  answer: string
  @State optionStatus:OptionStatus = OptionStatus.Default
  @Prop selectedOption:string
  //@Prop只能修饰number、boolean、string类型以及他们的数组
  @Prop @Watch('onAnswerStatusChange') answerStatus:AnswerStatus

  onAnswerStatusChange(){
    if(this.option===this.answer){
      this.optionStatus = OptionStatus.Right
    }
    else {
      if(this.option === this.selectedOption)
      {
        this.optionStatus = OptionStatus.Wrong
      }
      else {
        this.optionStatus = OptionStatus.Default
      }
    }
  }

  getBgColor(){
    switch(this.optionStatus){
      case OptionStatus.Right:
        return '#ff6dbe4c'
      case OptionStatus.Wrong:
        return '#ffef6262'
      default :
        return Color.White
    }
  }

  build() {
    Stack(){
      Button(this.option)
        .optionButtonStyle({
          bg: this.getBgColor(),
          font: this.optionStatus === OptionStatus.Default?Color.Black:Color.White
        })

      if(this.optionStatus === OptionStatus.Right){
        Image($r('app.media.ic_right'))
          .width(22)
          .height(22)
          .offset({x:10})
      }
      else if(this.optionStatus === OptionStatus.Wrong){
        Image($r('app.media.ic_wrong'))
          .width(22)
          .height(22)
          .offset({x:10})
      }
    }
    .alignContent(Alignment.Start)
  }
}

@Extend(Button) function optionButtonStyle(color: {
  bg: ResourceColor,
  font: ResourceColor
}) {
  .width(240)
  .height(48)
  .fontSize(16)
  .type(ButtonType.Normal)
  .fontWeight(FontWeight.Medium)
  .borderRadius(8)
  .backgroundColor(color.bg)
  .fontColor(color.font)
}

@Extend(Button) function controlButtonStyle(color: {
  bg: ResourceColor,
  border: ResourceColor,
  font: ResourceColor
}) {
  .fontSize(16)
  .borderWidth(1)
  .backgroundColor(color.bg)
  .borderColor(color.border)
  .fontColor(color.font)
}

//打卡弹窗
@CustomDialog
struct ResultDialog {
  answeredCount: number;
  rightCount: number;
  timeUsed: number;
  resetPractice: () => void;
  startPractice: () => void;
  controller: CustomDialogController = new CustomDialogController({
    builder: ResultDialog
  })

  //用于存储登录后的token字符串。可通过判断该字符串来判断是否登录
  @StorageProp('token') token: string = ''

  //用于存储当前Tabs组件中访问的子页面的索引，方便登录后跳转到对应的子页面
  @StorageLink('currentTabIndex') currentTabIndex: number = 0

  build() {
    Column({ space: 10 }) {
      Image($r('app.media.ic_close'))
        .width(25)
        .height(25)
        .alignSelf(ItemAlign.End)
        .onClick(() => {
          this.controller.close()
          this.resetPractice()
        })
      Column({ space: 10 }) {
        Image($r('app.media.img_post'))
          .width('100%')
          .borderRadius(10)
        StatItem({
          icon: $r('app.media.ic_timer'),
          name: '用时',
          fontColor: Color.Black
        }) {
          Text(convertMillisecondsToTime(this.timeUsed))
        }

        StatItem({
          icon: $r('app.media.ic_accuracy'),
          name: '准确率',
          fontColor: Color.Black
        }) {
          Text((this.answeredCount === 0 ? 0 : (this.rightCount / this.answeredCount * 100).toFixed()) + '%')
        }

        StatItem({
          icon: $r('app.media.ic_count'),
          name: '个数',
          fontColor: Color.Black
        }) {
          Text(this.answeredCount.toString())
        }

        Divider()
        Row({ space: 30 }) {
          Button('再来一局')
            .controlButtonStyle({
              bg: Color.Transparent,
              border: Color.Black,
              font: Color.Black
            })
            .onClick(() => {
              this.controller.close()
              this.resetPractice()
              this.startPractice()
            })
          Button(this.token?'立即打卡':'登录打卡')
            .controlButtonStyle({
              bg: Color.Black,
              border: Color.Black,
              font: Color.White
            })
            .onClick(async () => {
              this.controller.close()
              this.resetPractice()

              if(this.token){
                //如果已登录，进行打卡，
                // 发送打卡请求
                await createPost({
                  rightCount: this.rightCount,
                  answeredCount: this.answeredCount,
                  timeUsed: this.timeUsed
                })
                promptAction.showToast({ message: '打卡成功' })
                // 通知,需要再页面最上方导入import emitter from '@ohos.events.emitter'
                emitter.emit({ eventId: 1 })
                // 打卡后跳转到打卡圈
                this.currentTabIndex = 1
              }
              else {
                // 如未登录，跳转到登录页面。注意，需在当前页面导入router模块
                router.pushUrl({
                  url: 'pages/LoginPage',
                  //传递打卡参数，用于后续实现打卡功能
                  params: {
                    rightCount: this.rightCount,
                    answeredCount: this.answeredCount,
                    timeUsed: this.timeUsed
                  } })
              }
            })
        }
      }
      .backgroundColor(Color.White)
      .width('100%')
      .padding(20)
      .borderRadius(10)
    }
    .backgroundColor(Color.Transparent)
    .width('80%')
  }
}