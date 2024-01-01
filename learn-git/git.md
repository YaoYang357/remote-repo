![image-20231231160823939](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231160823939.png)

# 【Geekhour】一小时Git教程

​	Git是一个免费开源的分布式版本控制系统，它使用一个特殊的叫做**仓库**的数据库来记录文件的变化，仓库中的每个文件都有一个完整的**版本历史记录**，可以看到谁在什么时间修改了哪些文件内容，可以在需要时将文件恢复到之前的某一个版本。

![image-20231231161150497](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231161150497.png)

​	目前世界上最流行的版本控制系统有两种，一种是集中式版本控制系统，如：SVN、CVS等等，留哪个一种是分布式版本控制系统，如：Git、Mercurial等等。

​	集中式版本控制系统工作流程如下图，所有文件都保存在中央服务器上，每个人的电脑上只保存了一个副本，当你需要修改文件的时候，首先要从中央服务器上下载最新的版本，然后添加修改内容，修改完成后再上传回中央服务器。

![image-20231231161823243](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231161823243.png)

​	优点是使用起来非常简单，只需要从中央服务器上下载最新的版本，修改完成后再上传到中央服务器即可，不需要考虑其他问题。它的缺点也非常明显：中央服务器的单点故障问题，如果中央服务器出现故障或者网络连接出现问题，那么所有人都无法工作了。

![image-20231231162148908](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231162148908.png)

​	分布式版本控制系统下每个人的电脑上都有一个完整的版本库，可以在本地进行修改，不需要考虑网络问题（git存储的是元数据，保存的是不同版本间的差异，而不是所有文件）。当需要将我们的修改内容分享给其他人的时候，只需要将仓库互相同步一下就可以了。

Git已经成为了目前世界上最先进的分布式版本控制系统。

---

git的使用方式主要有三种：

- 命令行：最基本、最常用的方式，在终端中输入git命令的方式来使用git（推荐）
- 图形化界面（GUI）
- IDE插件/扩展：VScode集成了源码管理器

为了区分Linux操作系统中的命令，Git的所有命令都以“git”开头，后面跟着具体的命令。

![image-20231231164817439](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231164817439.png)

蓝色背景部分是当前所在目录的位置，波浪线表示用户的主目录，绿色背景部分是git的分支名称和当前仓库的状态。不是必须配置的。

在使用git之前第一步就是先使用git config命令配置一下用户名和邮箱，这样在提交时才能识别出是谁提交的内容。

![image-20231231165200695](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231165200695.png)

一般不会使用system参数，最多也就是用“--global”参数。用户名中间存在空格，所以需要双引号把它括起来，如果没有空格则双引号可以省略。

![image-20231231165346869](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231165346869.png)

这两条命令只需执行一次即可。

`git config --global credential.helper store`这句命令可以保存用户名和密码，这样就不用每次都输入了

`git config --global--list `查看刚刚的配置信息

之后就可以用git来管理我们的代码了。

---

**如何新建一个版本库（仓库）来对本地的代码进行管理？**

版本库/仓库：英文名叫Repository（ / *rɪˈpɒzətri*），简称Repo

---

*这个up知识太密集了，以下笔记改为听完之后在实践过程中记录。*

git init

git clone

---

![image-20231231171505857](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231171505857.png)

git的本地数据管理分为以上三个区域

- 工作区就是我们自己电脑上的目录，在资源管理器中能够看到的文件夹就是工作区
- 暂存区也称为索引index，是一种临时存储区域，用于保存即将提交到git仓库的修改内容，非常重要的区域
- 通过`git init`命令创建的仓库，包括项目历史和元数据，是git存储代码和版本信息的主要位置

​	简单来说，工作区就是我们实际操作的目录，暂存区就是中间区域，用于临时存放即将提交的修改内容，本地仓库是Git存储代码和版本信息的主要位置。

![image-20231231172056168](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231172056168.png)

工作区就是生产车间，暂存区就是货运工具（平板货车等），本地仓库就是仓库。

![image-20231231172315356](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231172315356.png)

可以将修改的文件先添加到暂存区中，然后再把暂存区中的文件统一执行一下提交操作。

git中的文件也存在几种状态：

- 未跟踪就是新创建的还没有被git管理起来的文件；
- 未修改就是已经被git管理起来但是文件的内容没有变化；

![image-20231231172642196](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231172642196.png)

![image-20231231172742953](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231172742953.png)

`git commit`只会提交暂存区中的文件，而不会提交工作区中的其他文件。

需要使用`git commit -m "XXX"`-m参数来指定提交的信息，这个信息会被记录到仓库中，如果不指定-m这个参数，那么git commit命令会进入一个交互式界面，默认会使用Vim编辑提交信息（我之前已经设置为VSCode了）。

`git add .`其中.表示当前目录，即将当前目录下所有文件添加到暂存区中。`git add *.txt`则表示将所有".txt"结尾的文件添加到暂存区中。

`git log --oneline`查看简介的提交记录。

![image-20231231174933843](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231174933843.png)

`git reset`用于回退版本

![image-20231231175034877](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231175034877.png)

**mixed是默认参数**，对勾表示保留该区内容，叉号表示删除该区内容。

`git reset HEAD^`表示使用mixed参数回退到上一个版本，如果不使用`HEAD^`，那么需要使用版本前面的字符串指定要回退的版本（通过`git log --oneline`查看）。

在使用场景方面，soft和mixed的作用基本相似，区别就在于是否保留暂存区的内容。一般来说，在我们提交了多个版本，但是又觉得这些提交没有太大意义，可以合并成一个版本的时候，就可以通过这两个参数来进行回退之后再重新提交。他们的区别就是再重新提交之前，混合模式需要执行一下get add操作来将变动的内容重新添加到暂存区，而soft模式就不需要了。

`git reflog`命令查看历史记录，找到误操作之前的版本号，然后使用`git reset --hard xxxxxxx`进行回退即可。

![image-20231231181433718](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231181433718.png)

以上命令查看工作区和暂存区内容。

---

git diff命令

![image-20231231212853645](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231212853645.png)

有时需要在一些没有图形化工具的服务器上使用git。

**git diff后面如果什么都不加得话会默认比较工作区和暂存区之间的内容差异。它会显示发生更改的文件以及更改的详细信息。**

![image-20231231213610977](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231213610977.png)

- 第一行提示了发生变更的文件
- 第二行，git会将文件内容使用哈希算法生成一个40位的哈希值，显示前7位，后面的100644表示文件的权限

红色的表示刚刚删除的内容，绿色的是添加的内容。

**还可以比较工作区和版本库之间的差异。**使用`git diff HEAD`

**还可以比较暂存区和版本库之间的差异。**使用`git diff cached`

**比较两个版本之间的差异。**使用`git diff 5af90b8 b270efb `此处两个版本号用作举例，除了使用提交ID之外，还可以使用**HEAD**来表示当前分支的最新提交。

`git diff HEAD~ HEAD`用来比较当前版本和上一个版本的差异，除了使用波浪线外，尖角号也可以`HEAD^`

还可以在波浪线前加上具体数字`git diff HEAD~2 DEAD`表示HEAD往前数两个版本。

![image-20231231214952029](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231214952029.png)

这样就只会查看file3的差异内容

![image-20231231215123351](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231215123351.png)

---

要删除一个已经提交到暂存区中的文件，首先在本地`rm file1.txt`此时是删除工作区的文件，接下来：

![image-20231231215413937](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231215413937.png)

使用`git ls-files`查看暂存区中的内容：

![image-20231231215509458](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231215509458.png)

使用`git add .`或者`git add file1.txt`将操作添加到暂存区：

![image-20231231215643878](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231215643878.png)

可以看到file1.txt已经不在了。

另一种方法是：`git rm xxx`直接删除：

![image-20231231215756860](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231215756860.png)

![image-20231231220241132](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231220241132.png)

---

### .gitignore文件

![image-20231231220319056](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231220319056.png)

![image-20231231220428868](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231220428868.png)

.gitignore文件的规则也非常简单，我们可以在这个文件中列出需要忽略的文件的模式，这样这些文件就不会被提交到版本库中。

![image-20231231220648735](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231220648735.png)

![image-20231231220858479](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231220858479.png)

实际使用中忽略所有log文件，可以采用`*.log`来指定所有以log结尾的文件，修改.gitignore文件。

.gitignore文件生效有一个前提，就是这个文件不能是已经被添加到版本库中的文件，因为我们是先把other.log这个文件添加到了版本库中，然后才修改的.gitignore文件，所以.gitignore文件对other.log是没有作用的，因为它已经被添加到了版本库中。此时需要把other.log这个文件先从版本库中先删除掉。

如果只想删除暂存区中的文件而不是将暂存区和工作区中的文件都删除，就不能使用使用`git rm xxx` ，而是使用`git rm --cached other.log`，这样以后无论这个文件发生了什么变化，都不会被纳入到版本控制中了。

**.gitignore文件中还可以配置文件夹的名称。**

git默认不会将空文件夹纳入版本控制中（git默认不会将空文件夹添加到仓库里面），但是如果temp文件夹下面有文件的话，这个文件夹就会被纳入到版本控制中。

`git status -s`表示查看状态这个命令的简略模式，这个命令的回显最前面有两个问号，第一列表示暂存区的状态，第二例表示工作区的状态，在.gitignore中添加文件夹：

![image-20231231231436091](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231231436091.png)

注意文件夹的格式是以斜线结尾的，这样才能正确的忽略文件夹。

![image-20231231231652643](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231231652643.png)

M表示.gitignore文件被修改过。

**匹配规则：**

![image-20231231232024314](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231232024314.png)

**Glob模式就是指shell所使用的简化了的正则表达式。**

![image-20231231232329883](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231232329883.png)

感叹号表示要忽略指令模式以外的文件或者目录，实例：

![image-20231231232447497](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231232447497.png)

![image-20231231232810077](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20231231232810077.png)

github上提供了各种常用语言的忽略文件的模板，在新建仓库的时候可以直接使用。

---

**远程仓库：如何创建远程仓库并克隆到本地？**

Github是一个非常流行的代码托管平台，世界上超过90%的开源项目都托管在Github上。

![image-20240101133226143](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101133226143.png)

Github左上角的搜索框可以搜索我们想要的仓库：

![image-20240101133310516](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101133310516.png)

![image-20240101133324657](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101133324657.png)

![image-20240101133338209](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101133338209.png)左上角

左上角显示分支和tag。

![image-20240101133404498](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101133404498.png)

右面列出了这个仓库的一些概要信息，发布的版本数、贡献者、使用的语言等等

![image-20240101134826146](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101134826146.png)

HTTPS方式在把本地代码push到远程仓库的时候需要验证用户名和密码，SSH不需要验证用户名和密码，但是需要在Github上添加SSH公钥的配置（推荐，安全、方便）。2021年8月13日后，用户名+密码方式已经被Github停止使用了，可以用token或者web auth验证。

![image-20240101135302954](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101135302954.png)

ssh方式使用前需要**配置ssh密钥**，具体目录和命令见上图。

![image-20240101140325420](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101140325420.png)

**输入密钥的文件名称，如果是第一次使用这个命令直接回车就好了（在根目录）！如果之前已经生成过则会覆盖之前生成的密钥文件，而且操作不可逆。**

-t 指定协议为RSA

-b 指定生成的大小为4096

![image-20240101140749058](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101140749058.png)

![image-20240101140832003](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101140832003.png)

![image-20240101140840528](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101140840528.png)

![image-20240101140919334](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101140919334.png)

将公钥文件中的内容复制到下图SSH keys中的新建项来：

![image-20240101141020011](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101141020011.png)

![image-20240101141152830](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101141152830.png)

![image-20240101141933132](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101141933132.png)

![image-20240101141925769](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101141925769.png)

如果是指定文件名的配置文件，还需要增加一步配置：创建config文件，并在其中加入# github开头的5句内容，当我们访问github.com的时候，指定使用ssh下的test这个密钥。

![image-20240101142800571](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101142800571.png)

这只是我们本地仓库的状态，并没有提交到远程仓库中。本地仓库和远程仓库是相互独立的两个仓库。我们可以在本地仓库中做任何修改，但是这些修改并不会影响到远程仓库，同样，远程仓库的修改也不会影响到本地仓库，因此需要一种机制来同步本地仓库和远程仓库的修改内容，让他们的状态保持一致。

![image-20240101143100575](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101143100575.png)

![image-20240101143157400](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101143157400.png)

执行push命令。

![image-20240101143230466](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101143230466.png)

---

**如果本地已经有了一个仓库，怎样才能把它放到远程仓库里面呢？**

![image-20240101143921203](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101143921203.png)

![image-20240101143940339](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101143940339.png)

![image-20240101143951147](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101143951147.png)

![image-20240101144119620](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101144119620.png)

![image-20240101144407635](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101144407635.png)

第二行命令的意思是指定分支的名称为main，如果分支的默认名称是main则这一行的名利给可以省略。最后一行命令的意思是把本地的main分支和远程的origin仓库的main分支关联起来。

![image-20240101144619061](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101144619061.png)

其实命令的全称如上所示，-u是upstream的缩写，意思就是上面的仓库关联，后面的main：main就是把本地仓库的main分支推送给远程仓库的main分支。如果本地分支和远程分支名称相同，就可以省略，只写一个main就好了。

![image-20240101150014536](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101150014536.png)

上面是本地分支叫“master”，push到远程的main分支中去。

![image-20240101150534914](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101150534914.png)

如果省略pull后面的参数，就是默认拉取仓库别名为origin的main分支。

**执行git pull的时候需要注意的一点就是，在执行完git pull之后，git会自动执行一次合并操作：**

![image-20240101150959248](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101150959248.png)

那么合并操作就会成功，

![image-20240101151032761](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101151032761.png)

这时需要手动解决一下冲突。

**从远程仓库获取内容还可以使用fetch命令，他们的区别在于fetch只是获取远程仓库的修改，但是并不会自动合并到本地仓库中，而是需要手动合并。**这些内容在后面分支知识的部分学习。

![image-20240101151255826](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101151255826.png)

![image-20240101151339475](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101151339475.png)

---

**学习如何使用github以外的两个代码托管平台**

![image-20240101191311991](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101191311991.png)

---

![image-20240101193036450](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101193036450.png)

![image-20240101194533681](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101194533681.png)

![image-20240101194813518](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101194813518.png)

---

![image-20240101195204301](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101195204301.png)

**通过`git branch`命令查看当前分支列表**，通过`git branch xxx`来创建一个新的分支，建立了新的分支后，还需要切换到这个分支上，使用`git checkout xxx`切换到xxx这个分支。

![image-20240101195829697](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101195829697.png)

使用`git checkout xxx`命令存在潜在的风险，如果分支名称和文件名称相同的话，就会出现歧义。checkout会默认切换分支而不是恢复文件。**为了避免这种歧义，git官方在2.23版本开始为我们提供了一个新的命令`git switch xxx`，语义更加明确。**

可以使用`git merge xxx`命令将不同的分支合并到当前分支中，merge后面的分支名称是将要被合并的分支。当前所在的分支就是合并后的目标分支。

![image-20240101200950211](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101200950211.png)

![image-20240101201125633](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101201125633.png)

以上命令用来查看分支图。

分支被合并后不会消失，如果不手工删除得话还是会存在的。

`git branch -d dev`-d参数表示删除已经完成合并的分支。如果没有被合并得话是不能使用-d参数来删除的。

![image-20240101201439069](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101201439069.png)

该命令可以强制删这个分支。

![image-20240101201553950](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101201553950.png)

---

### 解决合并冲突

一般情况下如果两个分支的修改内容没有重合的部分的话，合并分支非常简单，但是如果两个分支修改了同一个文件的同一行代码，git就不知道保留哪个分支的修改内容了，也就产生了冲突，这个时候就需要我们手动来解决冲突。

`git branch feat`其中feat就是feature的意思，一般用来表示开发某一个功能的分支。

![image-20240101203731622](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101203731622.png)

**小技巧：提交命令后面加上-a参数，就可以一个命令完成添加暂存和提交两个动作。（这个只对已经添加过的文件生效，如果是新文件就不能使用-a这个命令）。-a -m也可以省略成-am。**

![image-20240101204442875](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101204442875.png)

![image-20240101204515033](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101204515033.png)

使用`git status`查看冲突文件的列表，**也可以使用`git diff`查看冲突的具体内容**：

![image-20240101204618125](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101204618125.png)

可以使用`git merge --abort`来终止合并。

![image-20240101210027434](C:\Users\Dell\AppData\Roaming\Typora\typora-user-images\image-20240101210027434.png)