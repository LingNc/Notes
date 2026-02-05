        很多人喜欢用OpenWrt里面的OpenClash插件，是因为这个插件可以根据访问地址自动分流，以及多节点开启负载均衡，但是由于OpenClash插件的作者已经永久停更，并且OpenClash插件的设置比较繁琐，反人类操作，所以博主平时喜欢用OpenWrt的Passwall插件。其实Passwall插件同样具备了自动分流和负载均衡的功能，有些小伙伴不会设置于是私我，肯请写一篇设置的教程：

1、在进行以下的设置之前，先保证你安装的OpenWrt能联网并且你的机场节点可以正常科学出国，打开OpenWrt的Passwall插件，进入节点列表，随便找一个节点，点“修改”：

[![](https://wp.gxnas.com/wp-content/uploads/2024/07/1.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/1.jpg)

2、这里需要记录一下四个参数：类型、密码、加密方式、TCP快速打开；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/2.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/2.jpg)

3、再去看别的节点，多看几个节点；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/3.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/3.jpg)

4、核对一下类型、密码、加密方式、TCP快速打开，确保所有的节点这四个参数都是一样的；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/4.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/4.jpg)

5、进入负载均衡，在“开启负载均衡”处打勾；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/5.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/5.jpg)

6、设置控制台账号和密码，添加；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/6.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/6.jpg)

7、根据自己实际情况把需要使用的节点添加进来（我是把所有的节点全部添加进去），同一个机场负载均衡端口用同一个（这个端口号记录下来，后面要用到），如果有多个机场的，负载均衡端口要设置不同的端口，添加完成后，点右下角“保存&应用”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/7.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/7.jpg)

8、点“进入界面”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/8.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/8.jpg)

9、输入在第6个步骤填写的控制台的账号和密码，登录；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/9.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/9.jpg)

10、能看到如下图的信息就表示负载均衡已设置好节点（绿的表示该节点正常，红的表示该节点不通）；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/10.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/10.jpg)

11、点“节点列表”，添加；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/11.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/11.jpg)

12、根据你的机场类型去设置下图：地址写127.0.0.1，类型、密码、加密方式、TCP快速打开这四个参数按照第4个步骤看到的内容填写，如果有多个机场的可以建立多个，填写完成后点右下角“保存&应用”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/12.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/12.jpg)

13、在“节点列表”处找到“Xray分流：分流总节点”，点“修改”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/13.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/13.jpg)

14、根据自己实际情况设置分流所使用的节点，OpenAI不可以使用港澳台的节点，建议使用美国节点，其他的使用选择第12个步骤建立好的“负载均衡”，设置完成后点右下角“保存&应用”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/14.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/14.jpg)

15、基本设置，Socks配置，添加；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/15.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/15.jpg)

16、节点选择“Xray分流：分流总节点”，设置好Socks监听端口和Http监听端口，点右下角“保存&应用”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/16.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/16.jpg)

17、节点备注写“本机Socks5”，类型为“Socks”，端口为上一步骤设置的Socks端口号，点右下角“保存&应用”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/17.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/17.jpg)

18、按照下图开启Passwall插件的总开关和Socks主开关，TCP节点选择“本机Socks5”，Socks5节点选择“Xray分流：分流总节点”，Socks监听端口和Http监听端口填写第16个步骤设置的端口号；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/18.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/18.jpg)

19、DNS标签参考下图设置；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/19.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/19.jpg)

20、模式参考下图设置；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/20.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/20.jpg)

21、日志标签，把“启用TCP节点日志”和“启用UDP节点日志”两个地方的打勾去掉，点右下角“保存&应用”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/21.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/21.jpg)

22、到此，基本的设置就设置好了，检测一下百度连接和谷歌连接是OK的，如果谷歌连接测试不通过的话，到第6个步骤把负载均衡里面的健康检查类型由“URL测试（passwall内置实现）”改为“TCP”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/22.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/22.jpg)

---

       由于OpenWrt默认的节点分流设置较为简单，分流的精准度较差，建议根据自己实际情况深入设置一下分流规则，使分流规则更精准：

1、打开规则管理，比如我要对OpenAI的分流设置进行完善，找到OpenAI，修改；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/24.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/24.jpg)

2、然后去打开这个【[地址](https://github.com/blackmatrix7/ios_rule_script/blob/master/rule/Shadowrocket/OpenAI/OpenAI.list)】，可以看到涉及到有关OpenAI的域名和IP，把“DOMAIN”开头和“DOMAIN-SUFFIX”开头所有的内容复制出来；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/23.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/23.jpg)

3、打开记事本，粘贴进去，按Ctrl+H进入替换模式，把“DOMAIN,”替换为“full:”，点“全部替换”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/25.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/25.jpg)

4、把“DOMAIN-SUFFIX,”替换为“domain:”，点“全部替换”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/26.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/26.jpg)

5、然后把记事本里面修改好的内容复制，到OpenWrt的“域名”处“geosite:openai”的下一行粘贴；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/27.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/27.jpg)

6、把这个【[地址](https://github.com/blackmatrix7/ios_rule_script/blob/master/rule/Shadowrocket/OpenAI/OpenAI.list)】如下图的IP网段内容复制；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/28.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/28.jpg)

7、放到OpenWrt的“IP”处粘贴，点右下角“保存&应用”；[![](https://wp.gxnas.com/wp-content/uploads/2024/07/29.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/29.jpg)

8、除了OpenAI以外，常用的地址有这些，根据自己的需求按照上面的方法自行去添加：

（1）[TikTok](https://github.com/blackmatrix7/ios_rule_script/blob/master/rule/Shadowrocket/TikTok/TikTok.list)（抖音国际版）

（2）[YouTube](https://github.com/blackmatrix7/ios_rule_script/blob/master/rule/Shadowrocket/YouTube/YouTube.list)

（3）[Gemini](https://github.com/blackmatrix7/ios_rule_script/blob/master/rule/Shadowrocket/Gemini/Gemini.list)

（4）[Netflix](https://github.com/blackmatrix7/ios_rule_script/blob/master/rule/Shadowrocket/Netflix/Netflix.list)

（5）[Cloudflare](https://github.com/blackmatrix7/ios_rule_script/blob/master/rule/Shadowrocket/Cloudflare/Cloudflare.list)

（6）[GitHub](https://github.com/blackmatrix7/ios_rule_script/blob/master/rule/Shadowrocket/GitHub/GitHub.list)

（7）[OneDrive](https://github.com/blackmatrix7/ios_rule_script/blob/master/rule/Shadowrocket/OneDrive/OneDrive.list)

（8）[Telegram](https://github.com/blackmatrix7/ios_rule_script/blob/master/rule/Shadowrocket/Telegram/Telegram.list)

[![](https://wp.gxnas.com/wp-content/uploads/2024/07/30.jpg)](https://wp.gxnas.com/wp-content/uploads/2024/07/30.jpg)

9、全部设置完成后就可以达到节点负载均衡以及按照分流规则同时使用不同节点的目的了。