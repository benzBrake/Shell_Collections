<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>欢迎使用RyLLMP一键安装LLMP脚本</title>
<style type="text/css" media="screen">
body { background: #e7e7e7; font-family: Verdana, sans-serif; font-size: 11pt; }
#page { background: #ffffff; margin: 50px 15% 50px 15%; border: 2px solid #c0c0c0; padding: 10px; }
#header { background: #4b6983; border: 2px solid #7590ae; text-align: center; padding: 10px; color: #ffffff; }
#header h1 { color: #ffffff; }
#body { padding: 10px; }
span.tt { font-family: monospace; }
span.bold { font-weight: bold; }
a:link { text-decoration: none; font-weight: bold; color: #C00; background: #ffc; }
a { text-decoration: none; font-weight: bold; color: #F00; background: #ffc; }
a:active { text-decoration: none; font-weight: bold; color: #F00; background: #FC0; }
a:hover { text-decoration: none; color: #C00; background: #FC0; }
</style>
</head>
<body>
<div id="page">
 <div id="header">
 <h1> Welcome to use RyLLMP </h1>
  恭喜，看到此页面，证明您的服务器已经成功安装了Lighttpd + PHP + MySQL + SQLite环境
 </div>
 <div id="body">
  <h2>PS</h2>
  <p>
   这是一个简单方便的一键部署LLMP脚本，可以在5分钟内帮你完成PHP网站环境的搭建
  </p>
  <p>
   您可以通过SFTP工具把您的网站上传到<a>/var/www</a>目录，开始您的建站之旅，其中MySQL数据库的用户名为<a>root</a>，密码为您安装时所输入的密码，SQLite 3数据库直接使用即可，祝您使用愉快！
  </p>

  <H2>服务器简要探针</H2>
  <ul>
   <li>操作系统：<?php $os = explode(" ", php_uname()); echo $os[0];?></li>
   <li>服务器名：<?php echo $_SERVER['SERVER_NAME'];?> </li>
   <li>解译引擎：<?php echo $_SERVER['SERVER_SOFTWARE'];?></li>
   <li>访问端口：<?php echo $_SERVER['SERVER_PORT'];?></li>
   <li>PHP版本：<?php echo PHP_VERSION;?></li>
   <li>根目录：  <?php echo $_SERVER['DOCUMENT_ROOT'] ;?></li>
   <li>新建虚拟机方法：<a href="https://blog.iplayloli.com/lighttpd-create-virtual-host-with-www.html">https://blog.iplayloli.com/lighttpd-create-virtual-host-with-www.html</a></li>
   <li>更多关于内容：<a href="https://blog.iplayloli.com/search/lighttpd/">https://blog.iplayloli.com/search/lighttpd/</a></li>
  </ul>

  <p style="font-size:12px;margin-bottom:0px;margin-top:20px;">
   Copyright <a href="http://blog.iplayloli.com/llmp.html">Ryan</a>. All Rights reseved &nbsp;&nbsp;-Made by <a href="http://blog.iplayloli.com/">Ryan</a>
  </p>
 </div>
</div>
</body>
</html>
