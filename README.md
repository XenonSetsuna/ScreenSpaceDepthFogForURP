2022/3/3

Renderer Feature写得有点问题，但是能跑，之后改了再上传。

使用很简单，把一个shader，cs脚本和renderer feature(其实也是cs脚本) 导入URP项目，然后找到Assets/Settings/ForwardRenderer.asset选中它，在Inspector面板可以看到下面有个添加Render Feature的按钮，把导入的renderer feature添加上去，然后在后处理里面找到depth fog挂上去就行了。

雾效设定里面有个噪声贴图的开关目前没用，因为效果不太好所以在shader里面我暂时注释掉了，如果你想试一下的话可以打开shader里面改一改启用。
