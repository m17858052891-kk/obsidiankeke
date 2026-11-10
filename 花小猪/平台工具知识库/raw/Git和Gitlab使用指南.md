<!-- 请注意：文档内的附件与图片将在 2026/05/30 15:28:33  失效，请您在有效期内及时下载并保存至本地
Note: Attachments and images in the document will expire at 2026/05/30 15:28:33. Please download and save them locally within the valid period.-->
## 第一部分：Git&Gitlab

### Git是什么？

> - Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.

==Git是目前世界上最先进的分布式版本控制系统。==

### Git能做什么？

### Git可以敏捷高效地满足项目管理中的需求，包括版本记录、内容比对、版本回退、权限管理、Milestone确定和工作分配等等，总的来说就是

> - 版本管理和多人协作。

- 举个栗子：写论文  
背景：论文写作耗时较长且常常由多人几经修改，于是有以下常见的命名方式：

- > 1. 论文-第一版-20171001.doc

  
挑战：往往用题目标明版本，版本多了，只凭版本号和时间难以回忆起具体更新内容；且当他人帮忙修改，自己也同时在修改时，需要大量睁大双眼人工比对合并内容的过程。

但是如果用了Git做版本管理，就可以轻松应对这一切！

### Git、GitHub和GitLab的区别

- Git是一种版本控制系统，是一种工具，用于代码的存储和版本控制。

- GitHub是一个基于Git实现的在线代码仓库，是目前全球最大的代码托管平台，可以帮助程序员之间互相交流和学习。

- GitLab是一个基于Git实现的在线代码仓库软件，你可以用GitLab自己搭建一个类似于GitHub一样的仓库，但是GitLab有完善的管理界面和权限控制，一般用于在企业、学校等内部网络搭建Git私服。

- GitHub和GitLlab两个都是基于Web的Git远程仓库，它们都提供了分享开源项目的平台，为开发团队提供了存储、分享、发布和合作开发项目的中心化云存储的场所。从代码的私有性上来看，GitLab 是一个更好的选择。但是对于开源项目而言，GitHub 依然是代码托管的首选。

Git安装与版本库初始化

### Git下载与安装

  
Git的下载地址为<https://git-scm.com/downloads>，按默认选项安装即可。  
安装完成后，打开"开始菜单" -- "Git" -- "Git Bash"，出现类似命令行的界面，则说明安装成功。

### 全局设置

  
因为Git是分布式版本管理系统，所以每个机器需要“自报家门”，即首先需要配置用户名和邮箱。（注意下面改成自己的用户名和邮箱）

1. `git config`` ``--global`` ``user.name`` ``"arkshifangzhou"`

2. `git config`` ``--global`` ``user.email`` ``"arkshifangzhou@didiglobal.com"`

### 版本库初始化

  
什么是版本库呢？版本库又被称为仓库（repository），可以理解为一个目录，在此目录下的文件的增删改都可以被追踪，也可以被回溯。  
如何创建版本库呢？首先，进入需要创建版本库的目录，Mac系统用户在相应目录下右键打开Terminal即可。然后，键入以下命令，初始化版本库：

1. `git init`

  
当可以看到.git目录时，版本库就创建好了（在文件夹未被隐藏的情况下）。

## 版本管理

### 工作区和暂存区

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/1700129843152/%E6%88%AA%E5%B1%8F2023-11-16%E4%B8%8B%E5%8D%886.17.15.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260529%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260529T072833Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=ced3383b9166374e578df2dabe6cbec9301f8e15cea5fa106cd48534be7df1a5)

刚刚创建版本库时所在的文件夹被称为工作区，.git目录就是版本库，index是暂存区。Git中设计了暂存区，用来存储目前的修改，随后这些修改将提交到当前分支上去（版本库创建时会自动创建一个master分支）。

### 版本的增删  
Git管理的是变更（Diff），而不是文件本身。  
查看状态：变更的增退改删，在提交到分支之前，都可以先查看工作区和暂存区变更情况：

1. `git status`

  
增：假设在工作区新建了文件[readme.md](http://readme.md)，将此修改提交到master分支：

1. `git add readme.md`

2. `git commit`` ``-m`` ``"Initial commit"`

  
删：假设在工作区删除了文件[readme.md](http://readme.md)，工作区和版本库会产生不一致。这时有两种情况，第一种是删错了，可以用版本库版本覆盖工作区版本，即只需要

1. `git checkout`` ``--`` ``readme.md`

  
第二种是确实不再需要该文件，可以在版本库删除对该文件的追踪（这里是删除对该文件继续追踪，历史的追踪仍可以被查到），即只需要

1. `git rm readme.md`

## 远程仓库

  
迄今为止，我们已经可以实现本地版本管理。Git是分布式版本管理系统，工程上可以在服务器上面建立起版本库，其他版本库通过与远程库的同步，实现对版本的集中管理。这种版本集中管理的实现，可以通过自己的服务器搭建，也有专门的网站提供代码托管服务，比如GitHub和GitLab。本节以GitLab为例，介绍本地版本库与远程版本库的同步。步骤如下：

1. 注册GitLab账号；

2. 建立与远程库的通信；

3. 与远程库同步。

### 注册GitLab账号

  
pass

### 建立与远程库的通信

  
本地库与远程库的通信可以基于SSH也可以基于HTTP，这里介绍基于SSH的方法。  
首先，如果用户目录下存在名为.ssh的文件夹，请跳过本步；Mac用户打开Terminal，键入

1. `ssh-keygen`` ``-t rsa`` ``-C`` ``"amyzhangrui@didiglobal.com"`

  
一路选默认选项，不设密码即可。  
然后，登录GitLab，"Settings" -- "SSH Keys" -- "Key" -- "Add key"。在Key文本框中插入公钥，即id_rsa.pub文件中的所有内容。

### 与远程库同步

  
首先，在GitLab上初始化一个版本库。登录GitLab，"New..." – "New Project" -- "Project name" -- "Project description" – "Visiability level" – "Create project"。

interval是指有公司GitLab权限的人都可以看，但不能推送和拉去内容；

private是指除了项目内成员，其他人对项目不可见。

然后，与远程库同步。进入版本库所在目录，Windows用户打开Git Bash，Mac用户打开Terminal。

对于本地已有Git仓库，将本地库推送至远程库

1. `git remote add origin [git@git.xiaojukeji.com](mailto:git@git.xiaojukeji.com):bwh_stg/strategy_monitor.git`

2. `git push`` ``-u origin`` ``--all`

  
命令git remote add是指添加远程库，origin是远程库的名字，可以改为其他，但惯用origin，方便区分。git@...是指远程库的地址，在GitLab该库的主页可以查到。命令git push是指向远程库推送。命令-u是指将本地库与远程库关联起来，只有第一次推送的时候需要加。命令--all是指推送所有分支。  
对于本地已有文件夹，但没建仓库，需先初始化仓库，再向远程推送

1. `git init`

2. `git remote add origin [git@git.xiaojukeji.com](mailto:git@git.xiaojukeji.com):bwh_stg/strategy_monitor.git`

3. `git add`` ``.`

4. `git commit`` ``-m`` ``"Initial commit"`

5. `git push`` ``-u origin`` ``--all`

  
对于本地什么也没有，直接拉远程仓库覆盖本地，需要克隆

1. `git clone [git@git.xiaojukeji.com](mailto:git@git.xiaojukeji.com):bwh_stg/strategy_monitor.git`

2. `cd test`

  
命令git clone是指将远程库克隆到本地。命令cd是Linux命令，是指进入文件夹。strategy_monitor是项目名。假设此时需要在本地创建文件[README.md](http://README.md)，再推送至远程

1. `touch README.md`

2. `git add README.md`

3. `git commit`` ``-m`` ``"add README"`

4. `git push`` ``-u origin master`

  
命令touch是指初始化文件。

## 项目管理

### 分支管理

  
pass

### 权限管理

  
登入GitLab，进入项目，"Settings" – "Members" – "Add to project"。各种权限含义：

- Guest：只能看看，以及“瞎BB”（提交issues和comments）；

- Report：上面的权限，外加可以拉取项目内容；

- Developer：上面的权限，外加可以推送代码到不受保护的分支，加版本号；

- Master和Owner：什么都可以干。

### Milestone管理

  
登入GitLab，进入项目，"Issues" -- " New issue" -- "Submit issue"。

## 在IDE中使用Git

### 在PyCharm中使用Git

  
PyCharm作为个人认为史上最好用的Python的IDE（集成开发工具），可以满足绝大多数开发需求。在PyCharm中开发项目，不需离开PyCharm，就可以实现Git版本管理，包括与远程库的同步，有两种方式：

1. 使用Git命令，点击PyCharm里的terminal，直接写Git命令就好（这里应去资源管理器打开图片PyCharm-terminal.png），如果PyCharm里面已经建了项目，路径就已经是在工作区了，无需cd到相应路径。

![](https://s3-ep-inter.didistatic.com/didoc-upload-file-prod/1653033522583/860096544.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260529%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260529T072833Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=9d06509ee1e4a3eb10625bdb901f4473d6587d36f6a06da13d716b5fbc40fab6)

1. 使用VCS“点点点”，

	1. 菜单栏"VCS" -- "Enable Version Control Integration" -- "Git" -- "ok"；

	2. 点击VCS（版本管理系统），克隆、推送、拉取，想做什么直接点点点就好了。。

![](https://s3-ep-inter.didistatic.com/didoc-upload-file-prod/1653033522710/860096543.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260529%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260529T072833Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=fd42046bf425cf245e1005ac9c6d5bc2cad5405b7fe75cf203bb4c2c5015298e)![](https://s3-ep-inter.didistatic.com/didoc-upload-file-prod/1653033522826/860096545.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260529%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260529T072833Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=2c6d3082adfa2fe43987a1fcbb2950a45ec5a703742bbb490f5f2c32a2620af0)

### 在RStudio中使用Git

  
pass

### 在DataGrip中使用Git

  
需要先安装插件，"File" -- "Settings" -- "Plugins"，依次安装Git Integration、CVS Integration和Terminal。剩下的和PyCharm一样，可以通过 CVS 或 Terminal 进行版本管理。

需要注意的是，在DataGrip中新建（或克隆）Git项目，需要重新配Data Source（数据源）。  

## Highlight

- **编码方式**：Git的编码方式和Linux系统是一样的，是UTF-8；对于协作来说，统一编码方式也是对项目有益的。因此，

	- 包括代码在内的文本文件需要用UTF-8，不然会乱码，

	- 代码文件记得写头文件，

	- 版本库的路径避免用中文，容易乱码。

	- 最好把IDE和文本编辑器的默认编码方式改为UTF-8。

- **编辑器**：避免用Windows的记事本编辑UTF-8编码的文件，因为记事本设计了一个很蠢的方式保存UTF-8文件，即在文件开头加了十六进制的标识。经记事本编辑的代码，容易在编译时各种跑不通。关于文本编辑器，Mac用户推荐sublime，推荐理由：好看；Windows用户推荐Notepad++，推荐理由：随便选的。

- **使用范围**：Git可以追踪一切文本文件的修改，.csv .txt等等，但追踪不了视频、图片和MS特有文件（比如Excel和PPT）的修改。

- **忽略变更**：对于不需追踪变化的文件，比如.log .zip .Rproj文件，可以写入名为.gitignore的文件，Git会自动忽略这些文件，也不会将这些文件推送远程。

	- 将所有不需要追踪的文件写入.gitignore中之后，可以通过git add .一次性加入一切（“大饼卷一切”），而不用逐个写文件名。对于.gitignore文件的内容，举个栗子

```PlainText
*.class
# Package Files #
*.log
.idea
*.iml
*.jar
*.war
*.ear
*.zip
.project
.settings
.classpath
target
logs
node_modules
.springBeans
.DS_Store
```
