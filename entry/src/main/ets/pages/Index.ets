import { AnswerPage } from './AnswerPage'
@Entry
@Component
struct Index {
  //用于存储当前访问标签页的索引
  @State currentTabIndex:number = 0

  build() {

    Tabs() {
      //答题
      TabContent() {
        // Text('答题页面').fontSize(50).fontWeight(FontWeight.Bold)
        AnswerPage()
      }.tabBar(this.tabbarBuilder(0,'答题',$r('app.media.ic_practice'),$r('app.media.ic_practice_selected')))


      //圈子
      TabContent() {
        Text('圈子').fontSize(50).fontWeight(FontWeight.Bold)


      }.tabBar(this.tabbarBuilder(1,'圈子',$r('app.media.ic_circle'),$r('app.media.ic_circle_selected')))


      //我的
      TabContent() {
        Text('我的页面').fontSize(50).fontWeight(FontWeight.Bold)
      }.tabBar(this.tabbarBuilder(2,'我的',$r('app.media.ic_mine'),$r('app.media.ic_mine_selected')))

    }
    .width('100%')
    .height('100%')
    .vertical(false)
    .barPosition(BarPosition.End)
    .onChange((index)=>{
      this.currentTabIndex = index
    })
  }


  //定义导航栏样式
  @Builder
  tabbarBuilder(tab_index: number, tab_title: string, tab_icon: Resource, tab_selected_icon: Resource) {
    Column({ space: 5 }) {

      Image(this.currentTabIndex===tab_index?tab_selected_icon:tab_icon)
        .width(25)
        .height(25)

      Text(tab_title)
        .fontSize(16)
        .fontColor(this.currentTabIndex===tab_index?'#ffaec6a2':'#ff6b6767')
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .backgroundColor('#fff')
  }
}