import tkinter
import tkinter.messagebox
import os
import os.path


# 获取当前工作目录
path = os.getcwd()
# 设置当前目录为工作目录
os.chdir(path)


# 创建应用程序
root = tkinter.Tk()
# 设置窗口标题
root.title('获取网页视频')
# 设置窗口大小
root['height'] = 200
root['width'] = 500

# 在窗口上创建标签组件
labeHint = tkinter.Label(root, text='请输入视频链接：', font=("微软雅黑",12), justify=tkinter.RIGHT, anchor='e', width=80)
# 显示该组件的位置及大小
labeHint.place(x=25, y=50, width=155, height=25)

# 在窗口创建输入网页链接的文本框，同时设置关联的变量
varLink = tkinter.StringVar(root, value='')
entryLink = tkinter.Entry(root, width=80, textvariable=varLink)
entryLink.place(x=180, y=50, width=270, height=25)

# 获取网页视频事件处理函数
def get_video():
    # 获取输入的网页链接
    url = entryLink.get()
    print(url)
    os.system('you-get {}'.format(url))
    varStatus.set('已完成')

# 创建按钮组件，同时设置按钮处理事件函数
button_start = tkinter.Button(root, text='开始', font=("微软雅黑",12), command=get_video)
button_start.place(x=380, y=105, width=50, height=25)

# 清空输入框内容事件处理函数
def emplt():
    varLink.set('')
    varStatus.set('已清空')

button_emplt = tkinter.Button(root, text='清空', font=("微软雅黑",12), command=emplt)
button_emplt.place(x=260, y=105, width=50, height=25)

# 处理完事件后给出结果提示
varStatus = tkinter.StringVar(root, value='')
status = tkinter.Label(root, font=("微软雅黑",12), textvariable=varStatus)
status.place(x=380, y=150, width=50, height=25)

# 启动消息循环
root.mainloop()

