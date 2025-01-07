# **注意！！！**

本文档仅做参考，因为很多api有错误或者没写（懒得改或者懒得写）,
具体api请参考`lib\network\http`目录下的具体文件。

dart的语法类似js，有js基础可以简单的看懂，
如果看不懂也可以问问ai，我自认为写的还行，不算难看懂。

---

# 一些特殊符号的意义

1. 空值：如果是空值，比如`''`，`[]`那么就说明不需要写（请求头，请求体）或者说没有值（返回体）
2. `...`：代表后面都是重复的格式，所以省略掉了
3. `***`：隐私打码
4. `###`：说明值的内容会单独说明
5. `< >`：代表这是一个必填的值，最后的结果不需要`<>`

# 请求头特殊内容详解

## app-channel

分流相关，分流一二三分别对应1 2 3 的值

## authorization

鉴权值

发送账号密码后返回的token

## time

当前时间的unix时间戳，精确到秒

## nonce

应该是一个不重复的值

这里采用

```python
nonce = str(uuid.uuid4()).replace("-", "")
```

的方式进行计算

## signature

(path（去掉第一个斜杠）+ time + nonce + method + api-key).lower

然后进行加密，这里描述可能会有偏差，所以直接使用代码演示
```
HashKey = "~d}$Q7$eIni=V)9\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn"
```

`Python`

```python
raw = "users/profile1724849044wmhjpadmtzqpyrr5d2ryeyct5j28r2c4getc69baf41da5abd1ffedc6d2fea56b"
HashKey = "~d}$Q7$eIni=V)9\\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn"

# 创建 HMAC SHA256

result = hmac.new(HashKey.encode(), raw.encode(), hashlib.sha256).hexdigest()
result = "2764e30863f311119d5a9bb779c8b083bcbc2bf28152feea2d9428220c286611"
```

> 注：这里是因为转译的问题所以和上面的HashKey不太一样，以上面的为准

`JavaScript`

```javascript
CryptoJS.HmacSHA256(raw, HashKey).toString(CryptoJS.enc.Hex)
```

获得的result就是signature

## image-quality

图片画质，共有四个选项，从低到原画为`low` `medium` `high` `original`

# 图片获取方法

## 请求头

```json
{
    ":authority": "###",
    ":method": "GET",
    ":path": "###",
    ":scheme": "https",
    "User-Agent": "###",
    "Host": "authority",
    "Connection": "Keep-Alive",
    "Accept-Encoding": "gzip"
}
```

### authority

虽然理论上来说，就是`fileServer`的值，但是实际上有些出入。

首先，有四种请求地址，为以下四种

1. `storage-b.diwodiwo.xyz`
2. `storage.diwodiwo.xyz`
3. `s3.picacomic.com`
4. `img.picacomic.com`

现在一个个的说明

1. 经过我的测试，如果返回的地址是`https://storage-b.picacomic.com`，那么就必须用这个请求地址，另外返回的地址和实际请求的地址不一样，需要注意一下，我上面写的是可用的地址。
2. 如果返回地址是`https://storage1.picacomic.com`的话，那么就用这个地址，没错，这个返回的地址也是错误的，我上面写的也是正确的地址。
3. 这个地址不会作为返回值返回，如果返回值是`https://storage1.picacomic.com`且选择分流为二或者三的话就会使用这个代替第二个地址进行请求。
4. 这个地址也不会返回，作用的地方为，非原画画质的本子图片，以及下载的本子和观看历史会用这个地址请求。

最后说明一下，2不能直连，所以可以和3互换，3可以直连

### path

在上面的时候说了四种地址，其中上面三种地址的请求地址如下所示

图片的`path`有的是这样的`"tobs/ac3bd4de-b089-4965-9048-6936b0b43bd3.png"`，但实际上只需要后面的值，也就是`ac3bd4de-b089-4965-9048-6936b0b43bd3.png`这一部分就行了，前面的不需要。

另外如果返回的path什么路径都没有，比如这种`"path": "67170ac6-09a8-452e-b646-934cc8f91946.jpg"`，那么也需要在前面加上`static/`。

比如说需要获取上面的图片，那么请求地址就是`https://storage-b.diwodiwo.xyz/static/ac3bd4de-b089-4965-9048-6936b0b43bd3.png`

第四种请求地址比较特殊，一般来说第四种的返回地址会是这样

```json
{
    "path": "tobeimg/aesNffZ5PLucRzlDv4t7K9isQFtjm6TsfecUaugKCow/rs:fit:400:400:0/g:ce/aHR0cHM6Ly9zdG9yYWdlMS5waWNhY29taWMuY29tL3N0YXRpYy85ZDk1MjIxMC04ZDFmLTRiNjgtODgwOS01ODVkOTQwZDYxZjguanBn.jpg",
    "fileServer": "https://storage1.picacomic.com"
}
```

这个时候就需要去掉地址前面的`tobeimg`，然后把后面地址拼到`https://img.diwodiwo.xyz/`后面就行了，比如说这个的请求地址就是

而使用`img.picacomic.com`的则是直接使用`https://img.diwodiwo.xyz/`+去掉前面的内容的`path`

比如说需要获取上面的图片，那么请求地址就是`https://img.diwodiwo.xyz/aesNffZ5PLucRzlDv4t7K9isQFtjm6TsfecUaugKCow/rs:fit:400:400:0/g:ce/aHR0cHM6Ly9zdG9yYWdlMS5waWNhY29taWMuY29tL3N0YXRpYy85ZDk1MjIxMC04ZDFmLTRiNjgtODgwOS01ODVkOTQwZDYxZjguanBn.jpg`

---

# 无效authorization

## 返回值

```json
{
    "code": 401,
    "error": "1005",
    "message": "unauthorized"
}
```

# 登录

## 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "POST",
    ":path": "/auth/sign-in",
    ":scheme": "https",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "content-type": "application/json; charset=UTF-8",
    "content-length": "46",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

## 请求体

```json
{
    "email": "***",
    "password": "***"
}
```

## 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "token": "***"
    }
}
```

---

# 注册

## 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "POST",
    ":path": "/auth/register",
    ":scheme": "https",
    "api-key": "###",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "1",
    "time": "1728570806",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "medium",
    "app-platform": "android",
    "app-build-version": "45",
    "content-type": "application/json; charset=UTF-8",
    "content-length": "###",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

## 请求体

```json
{
    "answer1": "#",
    "answer2": "#",
    "answer3": "#",
    "birthday": "###-##-##",
    "email": "###",
    "gender": "###",
    "name": "###",
    "password": "###",
    "question1": "#",
    "question2": "#",
    "question3": "#"
}
```

gender:m(男)/f(女)/bot(机器人)

## 返回体

```json
{
    "code": 200,
    "message": "success"
}
```

# 找回密码

实际上哔咔已经不支持找回密码，所这个没有任何意义，无论怎样都会返回
```json
{
    "code": 500,
    "error": ":(",
    "message": "--",
    "detail": "unexpected error"
}
```

而官方的网页版上则有说明
![[03 资源/图片/forget_password.png]]

---

# 本子推荐

## 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/collections",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

## 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "collections": [
            {
                "title": "本子妹推薦",
                "comics": [
                    {
                        "_id": "582186415f6b9a4f93dc6a6d",
                        "title": "仁義隷痴 (楽園追放 -Expelled from Paradise-)",
                        "thumb": {
                            "originalName": "cover.jpg",
                            "path": "a40e69d8-a666-4569-8249-0b826170d8a1.jpg",
                            "fileServer": "https://storage1.picacomic.com"
                        },
                        "author": "きむら秀一（歩く電波塔の会）",
                        "categories": [
                            "同人",
                            "短篇"
                        ],
                        "finished": true,
                        "epsCount": 1,
                        "pagesCount": 27,
                        "totalViews": 145070,
                        "totalLikes": 978
                    },
                    ...
                ]
            }
        ]
    }
}
```

---

# 搜索

## 搜索的界面

### 请求体

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/categories",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

### 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "categories": [
            {
                "title": "援助嗶咔",
                "thumb": {
                    "originalName": "help.jpg",
                    "path": "help.jpg",
                    "fileServer": "https://diwodiwo.xyz/static/"
                },
                "isWeb": true,
                "active": true,
                "link": "https://donate.bidobido.xyz"
            },
            {
                "title": "嗶咔小禮物",
                "thumb": {
                    "originalName": "picacomic-gift.jpg",
                    "path": "picacomic-gift.jpg",
                    "fileServer": "https://diwodiwo.xyz/static/"
                },
                "isWeb": true,
                "link": "https://gift-web.bidobido.xyz",
                "active": true
            },
            {
                "title": "小電影",
                "thumb": {
                    "originalName": "av.jpg",
                    "path": "av.jpg",
                    "fileServer": "https://diwodiwo.xyz/static/"
                },
                "isWeb": true,
                "link": "https://adult-movie.bidobido.xyz",
                "active": true
            },
            {
                "title": "小里番",
                "thumb": {
                    "originalName": "h.jpg",
                    "path": "h.jpg",
                    "fileServer": "https://diwodiwo.xyz/static/"
                },
                "isWeb": true,
                "link": "https://adult-animate.bidobido.xyz",
                "active": true
            },
            {
                "title": "嗶咔畫廊",
                "thumb": {
                    "originalName": "picacomic-paint.jpg",
                    "path": "picacomic-paint.jpg",
                    "fileServer": "https://diwodiwo.xyz/static/"
                },
                "isWeb": true,
                "link": "https://paint-web.bidobido.xyz",
                "active": true
            },
            {
                "title": "嗶咔商店",
                "thumb": {
                    "originalName": "picacomic-shop.jpg",
                    "path": "picacomic-shop.jpg",
                    "fileServer": "https://diwodiwo.xyz/static/"
                },
                "isWeb": true,
                "link": "https://online-shop-web.bidobido.xyz",
                "active": true
            },
            {
                "title": "大家都在看",
                "thumb": {
                    "originalName": "every-see.jpg",
                    "path": "every-see.jpg",
                    "fileServer": "https://diwodiwo.xyz/static/"
                },
                "isWeb": false,
                "active": true
            },
            {
                "title": "大濕推薦",
                "thumb": {
                    "originalName": "recommendation.jpg",
                    "path": "tobs/37a8f3cd-8645-4258-ba98-1882e42191dd.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "isWeb": false,
                "active": true
            },
            {
                "title": "那年今天",
                "thumb": {
                    "originalName": "old.jpg",
                    "path": "old.jpg",
                    "fileServer": "https://diwodiwo.xyz/static/"
                },
                "isWeb": false,
                "active": true
            },
            {
                "title": "官方都在看",
                "thumb": {
                    "originalName": "promo.jpg",
                    "path": "promo.jpg",
                    "fileServer": "https://diwodiwo.xyz/static/"
                },
                "isWeb": false,
                "active": true
            },
            {
                "title": "嗶咔運動",
                "thumb": {
                    "originalName": "picacomic-move-cat.jpg",
                    "path": "picacomic-move-cat.jpg",
                    "fileServer": "https://diwodiwo.xyz/static/"
                },
                "isWeb": true,
                "active": true,
                "link": "https://move-web.bidobido.xyz"
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6e9",
                "title": "嗶咔漢化",
                "description": "未知",
                "thumb": {
                    "originalName": "translate.png",
                    "path": "f541d9aa-e4fd-411d-9e76-c912ffc514d1.png",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6d1",
                "title": "全彩",
                "description": "未知",
                "thumb": {
                    "originalName": "全彩.jpg",
                    "path": "8cd41a55-591c-424c-8261-e1d56d8b9425.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6cd",
                "title": "長篇",
                "description": "未知",
                "thumb": {
                    "originalName": "長篇.jpg",
                    "path": "681081e7-9694-436a-97e4-898fc68a8f89.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6ca",
                "title": "同人",
                "description": "未知",
                "thumb": {
                    "originalName": "同人.jpg",
                    "path": "1a33f1be-90fa-4ac7-86d7-802da315732e.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6ce",
                "title": "短篇",
                "description": "未知",
                "thumb": {
                    "originalName": "短篇.jpg",
                    "path": "bd021022-8e19-49ff-8c62-6b29f31996f9.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "584ea1f45a44ac4f7dce3623",
                "title": "圓神領域",
                "description": "魔法少女小圓為主題的本子",
                "thumb": {
                    "originalName": "cat_cirle.jpg",
                    "path": "c7e86b6e-4d27-4d81-a083-4a774ceadf72.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "58542b601b8ef1eb33b57959",
                "title": "碧藍幻想",
                "description": "碧藍幻想的本子",
                "thumb": {
                    "originalName": "blue.jpg",
                    "path": "b8608481-6ec8-46a3-ad63-2f8dc5da4523.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6e5",
                "title": "CG雜圖",
                "description": "未知",
                "thumb": {
                    "originalName": "CG雜圖.jpg",
                    "path": "b62b79b7-26af-4f81-95bf-d27ef33d60f3.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6e8",
                "title": "英語 ENG",
                "description": "未知",
                "thumb": {
                    "originalName": "英語 ENG.jpg",
                    "path": "6621ae19-a792-4d0c-b480-ae3496a95de6.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6e0",
                "title": "生肉",
                "description": "未知",
                "thumb": {
                    "originalName": "生肉.jpg",
                    "path": "c90a596c-4f63-4bdf-953d-392edcbb4889.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6de",
                "title": "純愛",
                "description": "未知",
                "thumb": {
                    "originalName": "純愛.jpg",
                    "path": "18fde59b-bee5-4177-bf1f-88c87c7c9d70.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6d2",
                "title": "百合花園",
                "description": "未知",
                "thumb": {
                    "originalName": "百合花園.jpg",
                    "path": "de5f1ca3-840a-4ea4-b6c0-882f1d80bd2e.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6e2",
                "title": "耽美花園",
                "description": "未知",
                "thumb": {
                    "originalName": "1492872524635.jpg",
                    "path": "dcfa0115-80c9-4233-97e3-1ad469c2c0df.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6e4",
                "title": "偽娘哲學",
                "description": "未知",
                "thumb": {
                    "originalName": "偽娘哲學.jpg",
                    "path": "39119d6c-4808-4859-98df-4dda30b9da3b.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6d3",
                "title": "後宮閃光",
                "description": "未知",
                "thumb": {
                    "originalName": "後宮閃光.jpg",
                    "path": "dec122af-84bf-4736-b8f0-d6533a2839f7.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6d4",
                "title": "扶他樂園",
                "description": "未知",
                "thumb": {
                    "originalName": "扶他樂園.jpg",
                    "path": "73d8a102-1805-4b14-b258-a95c85b02b8a.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5abb3fd683111d2ad3eecfca",
                "title": "單行本",
                "thumb": {
                    "originalName": "Loveland_001 (2).jpg",
                    "path": "a29c241a-2af7-47f2-aae5-b640374b12ac.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6da",
                "title": "姐姐系",
                "description": "未知",
                "thumb": {
                    "originalName": "姐姐系.jpg",
                    "path": "91e551c5-a98f-4f41-b7a0-c125bd77c523.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6db",
                "title": "妹妹系",
                "description": "未知",
                "thumb": {
                    "originalName": "妹妹系.jpg",
                    "path": "098f612c-9d16-4848-9732-0305b66ed799.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6cb",
                "title": "SM",
                "description": "未知",
                "thumb": {
                    "originalName": "SM.jpg",
                    "path": "41fc9bce-68f6-4b36-98cf-14ab3d3bd19e.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6d0",
                "title": "性轉換",
                "description": "未知",
                "thumb": {
                    "originalName": "性轉換.jpg",
                    "path": "f5c70a00-538c-44b8-b692-d6c3b049e133.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6df",
                "title": "足の恋",
                "description": "未知",
                "thumb": {
                    "originalName": "足の恋.jpg",
                    "path": "ad3373c7-4974-45f5-b5d6-eb9490363314.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6cc",
                "title": "人妻",
                "description": "未知",
                "thumb": {
                    "originalName": "人妻.jpg",
                    "path": "e3359724-603b-47d8-905f-c88c5d38c983.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6d8",
                "title": "NTR",
                "description": "未知",
                "thumb": {
                    "originalName": "NTR.jpg",
                    "path": "e10cf018-e214-41fa-bf1c-376a6b7a24ea.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6d9",
                "title": "強暴",
                "description": "未知",
                "thumb": {
                    "originalName": "強暴.jpg",
                    "path": "4c3a9fb0-3084-4abf-bbc9-8efa33554749.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6d6",
                "title": "非人類",
                "description": "未知",
                "thumb": {
                    "originalName": "非人類.jpg",
                    "path": "b09840fe-8ca9-41ac-9e73-3dd68e426865.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6cf",
                "title": "艦隊收藏",
                "description": "未知",
                "thumb": {
                    "originalName": "艦隊收藏.jpg",
                    "path": "1ed52b9e-8ac3-47ae-bafc-c31bfab9b3d5.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6d7",
                "title": "Love Live",
                "description": "未知",
                "thumb": {
                    "originalName": "Love Live.jpg",
                    "path": "b2ae70d1-1c0e-415f-b3f8-0f6f17626387.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6dc",
                "title": "SAO 刀劍神域",
                "description": "未知",
                "thumb": {
                    "originalName": "SAO 刀劍神域.jpg",
                    "path": "f7c0ccc3-6baf-4823-b2b5-a7a83d426d4c.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6e1",
                "title": "Fate",
                "description": "未知",
                "thumb": {
                    "originalName": "Fate.jpg",
                    "path": "44bf46b9-415e-490b-9b61-7916ef2cea53.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6dd",
                "title": "東方",
                "description": "未知",
                "thumb": {
                    "originalName": "東方.jpg",
                    "path": "c373bf9d-1003-453d-a791-f65dde937654.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "59041d54ccc747074b47dae4",
                "title": "WEBTOON",
                "description": "Webtoon 是一種始創於韓國的新概念網路漫畫，由「Web（網路）」及「Cartoon（漫畫、卡通）」組成，只需向上下滑動就能閱讀，不需翻頁，是一種專為電腦及行動裝置而設的漫畫。",
                "thumb": {
                    "originalName": "52a81f09-32a0-422b-bba3-207eb4d22520.jpg",
                    "path": "60c01af5-e9cd-4888-bf5c-89fb60a97cc7.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6e3",
                "title": "禁書目錄",
                "description": "未知",
                "thumb": {
                    "originalName": "禁書目錄.jpg",
                    "path": "c4314a3f-2644-473f-9b13-d78c8d857933.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5bd66e7e8ff47f7c46cf999d",
                "title": "歐美",
                "description": "歐美",
                "thumb": {
                    "fileServer": "https://storage1.picacomic.com",
                    "path": "0486b618-ccbb-4c77-a141-06351079eb9f.jpg",
                    "originalName": "67edd79c63e037afcd6309c25ad312a1.jpg"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6e6",
                "title": "Cosplay",
                "description": "未知",
                "thumb": {
                    "originalName": "Cosplay.jpg",
                    "path": "24ee03b1-ad3d-4c6b-9f0f-83cc95365006.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            },
            {
                "_id": "5821859b5f6b9a4f93dbf6d5",
                "title": "重口地帶",
                "description": "未知",
                "thumb": {
                    "originalName": "重口地帶.jpg",
                    "path": "4540db04-ebbe-4834-a77a-7b7995b5f784.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                }
            }
        ]
    }
}
```

## 支持哔咔

待做

## 哔咔排行榜

## 本子排行

### 请求头

```json
{
  "user-agent": "okhttp/3.8.1",
  "time": "###",
  "accept-encoding": "gzip",
  "image-quality": "original",
  "app-platform": "android",
  "authorization": "###",
  "app-channel": "1",
  "app-build-version": "45",
  "accept": "application/vnd.picacomic.com.v1+json",
  "app-uuid": "defaultUuid",
  "host": "picaapi.picacomic.com",
  "signature": "318d54b4be7c89691eaad7361783a077588600ec452f33f263ce4e924d894c2a",
  "app-version": "2.2.1.3.3.4",
  "nonce": "###",
  "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B"
}
```

url : `https://picaapi.picacomic.com/comics/leaderboard?tt=H24&ct=VC`

tt 后面即为按什么查找，H24为过去24小时，D7为过去一周，D30为过去一个月

## 游戏推荐

待做

## 点点拯救哔咔

待做

## 哔咔小程序

#todo

## 哔咔留言板

#todo

## 援助哔咔

`https://donate.bidobido.xyz`

## 哔咔小礼物

`https://gift-api.bidobido.xyz/gifts`

## 小电影

`https://adult-movie.bidobido.xyz/`

## 小里番

`https://adult-animate.bidobido.xyz/`

## 哔咔画廊

`https://paint-web.bidobido.xyz?token=****`

> 注：token是需要的，不然没法用

## 哔咔商店

`https://online-shop-web.bidobido.xyz`

## 哔咔运动

`https://move-web.bidobido.xyz`

---

> 注：以下为本子界面

## 最近更新

### 请求地址

`path: /comics?page=1&s=dd`

## 随机本子

### 请求地址

`path: /comics/random`

### 返回值

返回相对比较特别，记一下

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "comics": [...]
    }
}
```

## 其他的

### 请求头

一律为

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "###",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

其中path的计算方式为：

/comics?page=<`页数`>&c=<`title`>&s=<`排序方式`>

`title`：为搜索界面的返回值的title

排序方式：

`dd`：从新到旧

`da`：从旧到新

`ld`：喜欢数

`vd`：观看量

### 返回值

除了随机本子，一律为

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "comics": {
            "docs": [
                {
                    "_id": "66a9075369476246a982f3b8",
                    "title": "[兔黑]Kisskissbangbang",
                    "author": "加藤むう",
                    "totalViews": 3214,
                    "totalLikes": 132,
                    "pagesCount": 30,
                    "epsCount": 1,
                    "finished": true,
                    "categories": [
                        "短篇",
                        "同人",
                        "耽美花園"
                    ],
                    "thumb": {
                        "fileServer": "https://storage-b.picacomic.com",
                        "path": "tobeimg/pbrj0hYE0x0aTN5ZOMs00DduoAznfmpwZw.jpg",
                        "originalName": "KissKissBangBang (1).jpg"
                    },
                    "id": "66a9075369476246a982f3b8",
                    "likesCount": 132
                }
                ...
            ],
            "total": 58626,
            "limit": 20,
            "page": 1,
            "pages": 2932
        }
    }
}
```

| _id                   | 大概是漫画唯一标识符             |
| --------------------- | ---------------------- |
| title                 | 本子名字                   |
| author                | 作者名字                   |
| totalViews            | 观看数                    |
| totalLikes/likesCount | 总喜欢数                   |
| pagesCount            | 总共有多少页                 |
| epsCount              | 总共有多少篇                 |
| finished              | 是否完结                   |
| categories            | 分类                     |
| originalName          | 不知道是啥，大概率是图片本来的名字，意义不大 |
| path                  | 图片的路径                  |
| fileServer            | 请求地址                   |
| total                 | 漫画总数                   |
| limit                 | 一页最多显示多少漫画             |
| page                  | 当前页数                   |
| pages                 | 总共有几页                  |

## 搜索栏搜索

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "POST",
    ":path": "/comics/advanced-search?page=<页数>",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "content-type": "application/json; charset=UTF-8",
    "content-length": "55",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

### 请求体

```json
{
    "categories": [
        "###"
    ],
    "keyword": "###",
    "sort": "###"
}
```

`categories`：分类

`keyword`：搜索栏输入的值

`sort`：排序方式，上面有说

### 返回值

```json
{
    "comics": {
        "total": 6831,
        "page": 1,
        "pages": 342,
        "docs": [
            {
                "updated_at": "2024-09-15T08:57:47.036Z",
                "thumb": {
                    "originalName": "封面.jpg",
                    "path": "tobeimg/5WozpWOwgp6d-gC9On2pGM8oJuhDD8r7GJcaSamfsxM/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvN2I4OGFmNTItN2JkNS00NGZkLWEyZTAtMGNjNTUxNjk1ODc0LmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "ikuu",
                "description": "P站：ikuu\n模型很顶",
                "chineseTeam": "",
                "created_at": "2024-09-09T03:47:35.838Z",
                "finished": false,
                "categories": [
                    "人妻",
                    "全彩",
                    "長篇",
                    "CG雜圖"
                ],
                "title": "【3D】晨曦戰隊Aurora 1-6",
                "tags": [
                    "調教",
                    "3D",
                    "無修正",
                    "人妻",
                    "巨乳"
                ],
                "_id": "66e70689fe80d3757d2d45b5",
                "likesCount": 167
            },
            {
                "updated_at": "2024-09-14T10:25:06.947Z",
                "thumb": {
                    "originalName": "001.jpg",
                    "path": "tobeimg/kIrIhg8MPah5uIxFoTC-eMGs_bJ_DHTOYse2Dvmgh6U/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvMDcxMjJmNzgtOGI1MC00MTM3LWJjNjgtN2ZjOTkzZjNjZWYxLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "ちろたた",
                "description": "（忆之风汉化组交由授权代传）我与自称琉希的全裸少女相会了……",
                "chineseTeam": "影舞者&Loli喵汉化,忆之风汉化组",
                "created_at": "2022-05-09T13:36:11.303Z",
                "finished": true,
                "categories": [
                    "長篇",
                    "非人類",
                    "禁書目錄"
                ],
                "title": " 画皮ちゃん/画皮酱  1-33話",
                "tags": [
                    "劇情",
                    "非人類",
                    "觸手",
                    "自慰",
                    "浴室",
                    "巨乳",
                    "貧乳",
                    "搞笑",
                    "獸耳娘",
                    "連褲絲襪",
                    "妹妹",
                    "皮物"
                ],
                "_id": "6279b6e505f7dc3d82a2bec6",
                "likesCount": 185
            },
            {
                "updated_at": "2024-09-14T08:47:41.560Z",
                "thumb": {
                    "originalName": "封面.jpg",
                    "path": "tobeimg/48CCGUU_lY2ekg020OExUem5f6aoPfc2fpDaOt5V_nw/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvYWVkMjM5NmUtNThlOS00MDdmLTllNmQtNmZmMzBiNWFmZWJmLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "ペーター･ミツル",
                "description": "夫妻交姦 ~一旦做過就回不去了…比丈夫更厲害的婚外情SEX\n\n目前汉化只有1-27【汉化都是悦文社负责】\n16-25汉化版是我【魔】出资购买，由于有加密无法提取原档，只能截图\n汉化都是无修的",
                "chineseTeam": "悦文社",
                "created_at": "2024-03-28T12:59:04.238Z",
                "finished": false,
                "categories": [
                    "全彩",
                    "長篇",
                    "人妻",
                    "NTR",
                    "生肉"
                ],
                "title": "夫婦交姦～一度シたら戻れない…夫よりスゴい婚外セックス～ 1-37",
                "tags": [
                    "全彩",
                    "NTR",
                    "人妻",
                    "換妻",
                    "中出",
                    "口交",
                    "巨乳",
                    "劇情"
                ],
                "_id": "6606e42a1f1e7709c01fb3cc",
                "likesCount": 661
            },
            {
                "updated_at": "2024-09-13T23:10:32.514Z",
                "thumb": {
                    "originalName": "01.jpg",
                    "path": "tobeimg/eRWape-FYkN7LDpW7bYYpv3ieAQtcLksghJ72_QDTYQ/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvZTA2NjMxMjYtM2ZlMC00ZTYwLWEzYzUtOTA1YjZlNzQ4MDk0LmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "ひじき",
                "description": "无鸡之叹汉化组制作，仅供学习交流，喜欢请购买正版支持原作！\n前排避雷一些群体：梦女、饭圈、ky精（不懂就去查）、梗小鬼、洁党、大画家、翻译家、尴尬怪、贵物。都别来沾边！！！！\n3卷：「雫斗，别让其他男人碰你。」\n======分割线======\n4卷：「难道发情期提前了？」\n伴侣α·叶月和爱女雫、以及第二个孩子凑。\n在与最爱的家人度过每一天的同时，也在努力做好勤杂工的工作的Ω雫斗\n在美月的要求下，叶月要去长期出差。工作地点的高中生似乎对感到寂寞的雫斗产生了兴趣？\n叶月不在的第一个发情期，以及让人预感到未来的超人气Omegaverse系列第4卷！\n收录了描绘伴侣2人休息日的漫画加笔\n电子限定特典为1p加笔漫画",
                "chineseTeam": "无鸡之叹汉化组",
                "created_at": "2024-03-11T11:40:06.688Z",
                "finished": false,
                "categories": [
                    "耽美花園",
                    "長篇"
                ],
                "title": "请让我讨厌你吧（第3~4卷）丨嫌いでいさせて",
                "tags": [
                    "BL",
                    "女性向",
                    "ABO"
                ],
                "_id": "65f01ea0ed5aba55ac2b6a51",
                "likesCount": 229
            },
            {
                "updated_at": "2024-09-13T23:09:33.776Z",
                "thumb": {
                    "originalName": "01.jpg",
                    "path": "tobeimg/XmHfJ1el8SC0N-kV9ke_kIhxCAqm5dfxeNoPgYAD3uw/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvZjhhMDdmMzgtZDBjOC00MzA2LWEwZTItNTQxOGIwMWE0NmZmLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "羽纯ハナ",
                "description": "无鸡之叹汉化组制作，仅供学习交流，喜欢请购买正版支持原作！\n前排避雷一些群体：梦女、饭圈、ky精（不懂就去查）、梗小鬼、洁党、大画家、翻译家、尴尬怪、贵物。都别来沾边！！！！\n1卷：【为了心爱的人，我们成为了假伴侣】\n=====分割线=====\n2卷：【为了不被抢走，渴求吧】为了守护充满了和已故伴侣的回忆的家，贝瑞尔成为了夏亚的未婚妻。等待着贝瑞尔的，是上同一所学校、每天夏亚的任性摆布。然而在相处的过程中，贝瑞尔发现了夏亚隐藏的温柔与天真的姿态，让他的心渐渐得到了治愈。就在这时，重逢的竹马·伽尔告诉了他夏亚喜欢侍从堤欧的事实——。\n※本篇包含「Cuddle5～9话」和『Daria2023年12月号』收录的「Side 雨果 3话」。\n【附电子限定加笔漫画1p！】",
                "chineseTeam": "強人鎖男漢化組/无鸡之叹汉化组",
                "created_at": "2023-06-23T20:00:29.644Z",
                "finished": false,
                "categories": [
                    "耽美花園",
                    "非人類",
                    "長篇"
                ],
                "title": "Cuddle",
                "tags": [
                    "BL",
                    "純愛",
                    "劇情",
                    "女性向",
                    "非人類",
                    "ABO",
                    "獸人",
                    "furry"
                ],
                "_id": "6496c963ad60ec7a733abc9e",
                "likesCount": 1569
            },
            {
                "updated_at": "2024-09-13T23:08:21.166Z",
                "thumb": {
                    "originalName": "01.jpg",
                    "path": "tobeimg/szXZaEF0GVkfFAZsMIeCDpPdxZ9q-ktHOz1DJc8UZVA/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvYzFlNmI3MTctNWFiNC00ZTZmLTkwZjEtMDk5YmY1MDVkOWNmLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "須坂紫那",
                "description": "无鸡之叹汉化组制作，仅供学习交流，喜欢请购买正版支持原作！\n前排先避雷一些群体：梦女、饭圈（站队行为）、ky精、梗小鬼、洁党、大画家、“外交官”、尴尬怪。都别来沾边！！！！\n评论区禁止ky、引战、人身攻击、角色攻击。\n1卷：拥有少女漫画般恋爱梦的帅哥上班族·北大路。有一天，偶然得知公司同期的有马也在看少女漫画后，两人成为兴趣相投的朋友。虽然北大路第一次有了可以交谈的对象而兴奋不已，但实际上两人之间有很大的误会……!?社畜们的少女漫画恋爱故事。\n=========分割线=========\n2卷：身为少女漫画宅男的帅哥社畜北大路和同期的有马是恋人。对又帅又壮又可爱的有马神魂颠倒，不由得在夜间索求过了头。就在北大路想要克制一点时，却得知有马在撒谎避开自己……!?高品质王子×男子气概王子，社畜之间的恋爱故事·续篇!\n======分割线======\n3卷：非常喜欢少女漫画的职场精英·北大路和沉默寡言、很有男子气概的同事有马正在交往中。就在即将同居之时，北大路就要去大阪长期出差！？「不爱」系列第3弹！！",
                "chineseTeam": "无鸡之叹汉化组",
                "created_at": "2023-10-02T19:10:06.565Z",
                "finished": false,
                "categories": [
                    "耽美花園",
                    "長篇"
                ],
                "title": "我不可能爱上你（更新中） 丨君に恋するはずがない ",
                "tags": [
                    "BL",
                    "純愛",
                    "女性向"
                ],
                "_id": "651c58e344506c77357b7418",
                "likesCount": 581
            },
            {
                "updated_at": "2024-09-13T11:46:12.881Z",
                "thumb": {
                    "originalName": "P1.jpg",
                    "path": "tobeimg/i6Cbno-Aqgazvw7-Q3BV2ygT-J4LecCxYdRnHHwXS-0/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvMDFkYTJjMTQtNzNiNS00Nzk3LWE4ODYtYTdlZTI5YTBjNWZmLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "大森ペル太",
                "description": "（邮件委托代传，按要求匿名汉化）",
                "chineseTeam": "匿名",
                "created_at": "2024-09-13T10:27:13.073Z",
                "finished": true,
                "categories": [
                    "長篇"
                ],
                "title": "東山さん達は催〇術にかけられて・・・1-3[中国翻译]",
                "tags": [
                    "劇情",
                    "女高中生(JK) ",
                    "風紀委員",
                    "校服",
                    "洗腦 / 催眠",
                    "巨乳",
                    "中出",
                    "自慰",
                    "女僕裝",
                    "指交",
                    "潮吹",
                    "口交",
                    "亂交",
                    "野外 / 露出",
                    "比基尼",
                    "黑皮"
                ],
                "_id": "66e5afeafe80d3757d2d3985",
                "likesCount": 63
            },
            {
                "updated_at": "2024-09-13T08:10:24.921Z",
                "thumb": {
                    "originalName": "1.jpg",
                    "path": "tobeimg/_kCOOfP6TcueMPqnXTiOC_C8oBhZ5tVKEq-IsV2adsU/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvYjMyNDNiYjQtNWZlNC00OTc4LTg2OGUtZjZkNjlhMmJiYzFlLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "ししゃもハウス (あらきあきら)",
                "description": "更新1+α\n扶她百合節奏",
                "chineseTeam": "EZR個人漢化、羽喵个人翻译",
                "created_at": "2022-09-28T07:07:47.994Z",
                "finished": true,
                "categories": [
                    "扶他樂園",
                    "長篇"
                ],
                "title": "ふたゆりずむ1+0",
                "tags": [
                    "扶她",
                    "眼鏡",
                    "校服",
                    "口交",
                    "貧乳",
                    "連身假陽具",
                    "肛交"
                ],
                "_id": "6334040911087d0806c8033c",
                "likesCount": 158
            },
            {
                "updated_at": "2024-09-12T13:15:52.466Z",
                "thumb": {
                    "originalName": "1.jpg",
                    "path": "tobeimg/YhUaNG1m9MWN2NFiHqnsVVUu4mfo0GLf4Zby2_EpHec/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvNDEyZWFiOTItM2ZkMy00NjNmLWEzOTctMTc4NTdhNTgxOTgyLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "首切り",
                "description": "1「科学者ファーバー」\n2「彼女を知る者」\n3「剝製オークション 前日譚」\n4「剝製オークション 」\n5「闘技場」\n6「刑場」\n7「刺客」\n8「紅茶」",
                "chineseTeam": "Dcliang个人汉化",
                "created_at": "2024-09-03T16:08:13.343Z",
                "finished": true,
                "categories": [
                    "重口地帶",
                    "短篇"
                ],
                "title": "死体残酷物語",
                "tags": [
                    "短篇合集",
                    "血腥",
                    "非人類",
                    "強暴",
                    "眼鏡",
                    "腸露",
                    "斷肢",
                    "屍姦",
                    "首切",
                    "口交",
                    "短髮"
                ],
                "_id": "66d87184d745ca758cdfc6f4",
                "likesCount": 438
            },
            {
                "updated_at": "2024-09-12T00:03:58.363Z",
                "thumb": {
                    "originalName": "19卷封面 (1).jpg",
                    "path": "tobeimg/yOVh64byvBq0J_yd132t1igpxZIiElkQIoCSlecbxjQ/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvZTA4OTc5ZjUtODMxYS00ZTUxLTgxMzgtMDJlNGQ4ZTNmMmQzLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "野澤ゆき子、中村力斗",
                "description": "春天是离别与邂逅的季节、在中学毕业典礼上经历了第100次失恋的爱城恋太郎突然遇到了结缘与恋爱的神明。神明告诉恋太郎，他会在高中邂逅100位命运之人！ 但是，命运之人如果无法与恋太郎修成正果的话就会死！？ 知道了这个冲击性的事情后，恋太郎的纯情后宫高中生活开始了……\n\n备注：可乐萌授权转载，1-77话为单行本，有加笔和单行本特别篇",
                "chineseTeam": "可乐萌汉化组",
                "created_at": "2022-05-02T00:16:29.434Z",
                "finished": false,
                "categories": [
                    "純愛",
                    "後宮閃光",
                    "長篇",
                    "禁書目錄"
                ],
                "title": "超超超超超喜欢你的一百个女朋友",
                "tags": [
                    "後宮",
                    "校園",
                    "搞笑",
                    "野澤ゆき子、中村力斗",
                    "可乐萌汉化组"
                ],
                "_id": "626fcf969e8b0c01f06858a2",
                "likesCount": 603
            },
            {
                "updated_at": "2024-09-11T17:26:24.533Z",
                "thumb": {
                    "originalName": "053封面.png",
                    "path": "tobeimg/5SANatP6Hxm-Ik8tyPSawYe-f5GU9GKtW329x54D-JE/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvMjViNTg0M2EtZGQyNS00Y2U0LThhM2QtYzMyZGFiODcxZTAxLnBuZw.png",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "LANTIC",
                "description": "小情侣一起堕落了嘛，雌堕速度有点快哦\n这种援交学校的设定好色哦\n前26话传的骑兵版的，边传边看觉得不错，搞了个会员有无码版的，后面有时间把无码的也传\n增加1-26话无修版\n更新中......",
                "chineseTeam": "",
                "created_at": "2023-11-08T09:07:23.858Z",
                "finished": false,
                "categories": [
                    "全彩",
                    "CG雜圖",
                    "長篇",
                    "偽娘哲學",
                    "NTR"
                ],
                "title": " 风俗妹的原则",
                "tags": [
                    "援交",
                    "女裝",
                    "NTR",
                    "偽娘",
                    "墮落",
                    "雌墜",
                    "巨乳",
                    "女高中生(JK) ",
                    "學生",
                    "亂交",
                    "口交",
                    "口爆",
                    "肛內中出",
                    "中出",
                    "肛交",
                    "無修正"
                ],
                "_id": "654cf75351a3b072b6cdf957",
                "likesCount": 1043
            },
            {
                "updated_at": "2024-09-10T10:49:03.704Z",
                "thumb": {
                    "originalName": "工读生丫头 (1).jpg",
                    "path": "tobeimg/KNbGEHE6QlJq1e10ZU_ZNcfP8uWcTt5d2nxjuKmUT6Y/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvMTFiN2IzYzMtZjgzOC00YTU1LTlmMzItMDM3MWZmZTQ1Y2JhLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "LUXsumildo",
                "description": "感谢骑士君代发，皮皮狗子前辈自购图源；\n感谢Fuer马林君·金音彬的翻译校润，旺财嵌字。\n\n小科普：\n1·588的含义：指妓女，也指首尔清凉里588号地区，这里地标建筑是老清凉里火车站。\n这里从625韩战（也就是朝鲜战争）开始，就有大批的妓女鸡头和龟公老鸨在这里做生意，虽然这个世纪清凉里已经被警方大规模肃清了，但还是留下了588指代妓女的俚语；\n2·花娘：庆州方言里面妓女的意思，中国古代也有使用这个词来形容娼妓；\n3·橱窗屋：指卖淫场所，因为韩国的卖淫女们都被视为和衣服一样的轻贱货，会被塞进橱窗后面搔首弄姿的当展示品来推销；\n4·鳗鱼：韩国最常见的鳗鱼是뱀장어日本鳗鱼，一公斤生的就得足足35000韩币（约186元人民币），这小姐闯大祸了。",
                "chineseTeam": "LC整合汉化组",
                "created_at": "2024-09-06T17:25:54.168Z",
                "finished": true,
                "categories": [
                    "短篇",
                    "強暴",
                    "非人類"
                ],
                "title": "LUX·韩爱洞的精液抹布工读生丫头们03（原创系强暴H合集）",
                "tags": [
                    "強暴",
                    "巨乳",
                    "乳房",
                    "中出",
                    "脅迫",
                    "酒醉",
                    "非人類"
                ],
                "_id": "66e1af93d745ca758ce00a01",
                "likesCount": 138
            },
            {
                "updated_at": "2024-09-10T10:48:26.132Z",
                "thumb": {
                    "originalName": "1丫头 (12).jpg",
                    "path": "tobeimg/fZH5qxBhCefzX24_n8peuETKd4wEM9K-Rvusq-wMaeE/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvNDQ4MmY0ZDgtMmQxMi00MzFiLTkzZjItMTRjMmRiZjIxYjhhLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "LUXsumildo",
                "description": "感谢骑士君代发，皮皮狗子前辈自购图源；\n感谢Fuer马林君·金音彬的翻译校润，小林崽崽嵌字。\n\n小科普：\n1·DC：这个是韩网上“论坛”的俗称，不过是个蛮有时代感的称呼了；\n2·驱魔师：从服饰就能看出是朝鲜巫教，之前韩国上了个《朝鲜驱魔师》的电视剧，因为里面编剧（之前因为接受中国投资被骂过）撰写承认皮蛋等食物是中国的，“最大度的韩国”网友们气的原地破防直接把这剧抵制到腰斩了...\n更搞笑的造谣病毒论辱华的吃播韩癌姐米藏，因为投稿中喝了青岛啤酒就被各种反复辱骂了。\n3·小神婆：对年轻的女性驱魔师尊称；\n4·CCTV:这个词在日韩美英等地都默认是“监控”的意思；\n5·冷笑书云上鲁台，乖祥俱向眼中猜：引用宋代诗人张炜的《冬至》。\n",
                "chineseTeam": "LC整合汉化组",
                "created_at": "2024-09-06T11:22:21.332Z",
                "finished": true,
                "categories": [
                    "短篇",
                    "同人",
                    "姐姐系",
                    "NTR",
                    "強暴"
                ],
                "title": "LUX·韩爱洞的精液抹布丫头们03（强暴轮奸系）",
                "tags": [
                    "巨乳",
                    "乳房",
                    "口交",
                    "肛交",
                    "強暴",
                    "輪姦",
                    "姐姐",
                    "御姐",
                    "姐弟",
                    "強制高潮",
                    "顏射",
                    "NTR",
                    "性玩具",
                    "拘束"
                ],
                "_id": "66e1af83d745ca758ce009e7",
                "likesCount": 874
            },
            {
                "updated_at": "2024-09-10T07:32:18.663Z",
                "thumb": {
                    "originalName": "fengm.jpg",
                    "path": "tobeimg/mSkREZtRI9AiwfUz4nWNr9SxGOMY2B0Xab4xK9Twbww/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvYjg2ZjBmMTctZGQyMC00MDM1LWFlNWMtZTBmMjM5MzBiOTg4LmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "うらのひきだし (ニジィー)",
                "description": "",
                "chineseTeam": "",
                "created_at": "2024-09-09T05:36:57.596Z",
                "finished": true,
                "categories": [
                    "全彩",
                    "生肉"
                ],
                "title": "アソコのトレーナーは最高 1-2",
                "tags": [
                    "全彩",
                    "生肉",
                    "巨乳",
                    "中出"
                ],
                "_id": "66dff602e33b5b385466ab19",
                "likesCount": 37
            },
            {
                "updated_at": "2024-09-10T06:29:29.126Z",
                "thumb": {
                    "originalName": "1.jpg",
                    "path": "tobeimg/2zF-wmxim6pyWMFjJeshd95MLBwJ_KAb3YqfqoucFcw/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvNDE4NTZlMDctOWUyZS00OTVhLThkMDMtNzkzNzI5NWIzYjYxLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "むに工房 (桐江)",
                "description": "魅魔夢遊仙境 After! 第一卷",
                "chineseTeam": "濁音社",
                "created_at": "2024-09-10T06:25:42.997Z",
                "finished": true,
                "categories": [
                    "長篇",
                    "姐姐系"
                ],
                "title": "不思議の国のサキュバス あふたー! 第1巻",
                "tags": [
                    "正太",
                    "開大車",
                    "女性主導",
                    "巨乳",
                    "乳交",
                    "魅魔",
                    "手交",
                    "騎乗",
                    "手套",
                    "長筒襪",
                    "女裝",
                    "凹陷乳頭"
                ],
                "_id": "66e0026be33b5b385466afe8",
                "likesCount": 968
            },
            {
                "updated_at": "2024-09-10T06:20:25.823Z",
                "thumb": {
                    "originalName": "1.jpg",
                    "path": "tobeimg/lDwLPSqNpbXqmgKnllunl3uCbaP_GklKiP7yJ-eykzY/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvODlhZmM4NmMtOWZiYi00YjI0LWFiOWQtZTA0ZTVhZjRlMDk4LmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "どじろー",
                "description": "處女不能發情嗎？\n「你隨時可以找我幫你性處理哦♪」\n\n眾人稱羡的校園No.1完美情侶……雖然大家這麼以為，但其實兩人腦子裡滿滿都是下流的事!?\n因為不想被對方討厭，拚命隱藏自己的好色心情，持續著柏拉圖式的關係……但忍耐已經來到極限!?\n\n下面癢到爆炸的思春期女生之肉慾大爆發♪\n從一開始連載就引爆話題，在同人界也享有盛名的說故事高手どじろー老師，令人期待的首部單行本!!!",
                "chineseTeam": "暮想出版",
                "created_at": "2024-09-10T06:14:07.157Z",
                "finished": true,
                "categories": [
                    "單行本"
                ],
                "title": "処女がサカっちゃだめですか?",
                "tags": [
                    "無修正",
                    "老師",
                    "學生",
                    "黑皮",
                    "馬尾",
                    "自慰",
                    "口爆",
                    "口交",
                    "廁所",
                    "乳交",
                    "雙馬尾",
                    "校服",
                    "短髮",
                    "騎乗",
                    "顏射",
                    "中出",
                    "肉食系",
                    "橫切面",
                    "電車痴漢"
                ],
                "_id": "66e00235d745ca758ce00028",
                "likesCount": 5408
            },
            {
                "updated_at": "2024-09-09T12:46:35.781Z",
                "thumb": {
                    "originalName": "0007_00660_1174802354.jpg",
                    "path": "tobeimg/QLynzCZiwe94N7U8U_yMG6jydbE8YharxDeScY4wXqo/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvODZmMzM0MDAtNDMzNi00NmViLTgzOGYtMmQxMWM2OGZhNTJiLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "NP1",
                "description": "AI图",
                "chineseTeam": "",
                "created_at": "2023-12-24T11:49:19.040Z",
                "finished": false,
                "categories": [
                    "全彩",
                    "同人",
                    "CG雜圖"
                ],
                "title": "[PIXIV] NP1 (27500391)（AI）",
                "tags": [
                    "全彩",
                    "AI作畫",
                    "RE: 雷姆",
                    "原神",
                    "巨乳",
                    "RE: 拉姆",
                    "短髮",
                    "精靈",
                    "女僕",
                    "崩壞：星穹鐵道",
                    "和服",
                    "RE: 從零開始的異世界生活",
                    "姐妹",
                    "原神:刻晴",
                    "旗袍",
                    "妖精",
                    "雙馬尾",
                    "比基尼",
                    "魔法師",
                    "原神:甘雨"
                ],
                "_id": "65898bf2de0c0649221df7d0",
                "likesCount": 284
            },
            {
                "updated_at": "2024-09-09T10:59:35.869Z",
                "thumb": {
                    "originalName": "001.jpg",
                    "path": "tobeimg/na32fch2oHd35AM0Yr12DUEZgVC0HeKKgq8m_VykcJI/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvNmYzNjdjZTEtMWZhYy00MGVmLWEzZmEtMThkZTQ4ZjY0ZTIyLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "クール教信者",
                "description": "（无偿搬运，24.9.7更新第7卷生肉；23.10.2更新第5卷汉化）クール教信者明确18禁漫画连载中，有社交障碍的绘本作家-万光，因缘际会的与网路上认识的网友(不知道对方性别)，实际上却是巨乳女子大生同居，各种形形“色色“的生活剧，就此展开。zerobyw同意搬运。",
                "chineseTeam": "个人汉化,未知英文翻译",
                "created_at": "2021-09-22T16:53:21.449Z",
                "finished": false,
                "totalViews": 23966,
                "categories": [
                    "長篇",
                    "禁書目錄",
                    "生肉",
                    "純愛"
                ],
                "totalLikes": 2107,
                "title": "乳乳乳乳/チチチチ/Chichichichi 1-5卷汉化（更新至121话）",
                "tags": [
                    "劇情",
                    "巨乳",
                    "乳交",
                    "女大學生(JD)  ",
                    "日常",
                    "英語 ENG",
                    "生肉",
                    "妹妹",
                    "開大車"
                ],
                "_id": "614c9992de7be276a540b8c7",
                "likesCount": 2107
            },
            {
                "updated_at": "2024-09-09T03:31:14.335Z",
                "thumb": {
                    "originalName": "02.jpg",
                    "path": "tobeimg/y--cRfMfz0zBdWymIox4QddUXKreUsk5PS23wA-wnGY/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvNzY2ZjA3NDItZTY1YS00NTA4LWIyNjktYmFjOTEzM2E5YTBhLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "DATE",
                "description": "感谢多个汉化组，排名不分先后",
                "chineseTeam": "无毒汉化组、新桥月白日语社&HunJohn漢化、不咕鸟汉化组、四等两足牲口个人汉化、贽殿遮那个人汉化",
                "created_at": "2024-04-16T18:16:05.866Z",
                "finished": true,
                "categories": [
                    "長篇",
                    "性轉換"
                ],
                "title": "他人になるクスリ 1-6.2",
                "tags": [
                    "性轉",
                    "巨乳",
                    "自慰",
                    "憑依",
                    "女高中生(JK) "
                ],
                "_id": "6621389f5fe9ef5782ee47cb",
                "likesCount": 171
            },
            {
                "updated_at": "2024-09-08T07:09:40.998Z",
                "thumb": {
                    "originalName": "01.jpg",
                    "path": "tobeimg/D9-ky7ZARrJtqxJBxgVkndbSeAjqkI1Qws1Eb9LBL10/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvMjlhZGEzZDUtOWFmMC00MGM3LTlhYTMtN2E5NjliODI1ZGJjLmpwZw.jpg",
                    "fileServer": "https://storage-b.picacomic.com"
                },
                "author": "しっとりボウズ",
                "description": "感谢 面具人 委托汉化\n\n如果您对该作有兴趣，力所能及下可以购买原作来支持作者",
                "chineseTeam": "不咕鸟汉化组",
                "created_at": "2024-05-21T14:08:56.929Z",
                "finished": true,
                "categories": [
                    "長篇"
                ],
                "title": " 株式会社ずっぽし ご奉仕部性処理課メス穴サービス係【第1話】 (COMIC 真激 2023年3月号) [中国翻訳] [DL版]",
                "tags": [
                    "制服",
                    "情趣內衣",
                    "肉便器",
                    "蹦壞臉",
                    "口交",
                    "亂交"
                ],
                "_id": "664dec4e816264383c37536a",
                "likesCount": 127
            }
        ],
        "limit": 20
    }
}
```

| total        | 漫画总数                        |
| ------------ | --------------------------- |
| page         | 当前页数                        |
| pages        | 总共有几页                       |
| docs         | 本子信息数组                      |
| updated_at   | 上传时间                        |
| originalName | 不知道是啥，大概率是图片本来的名字，意义不大      |
| path         | 图片的路径                       |
| fileServer   | 请求地址                        |
| author       | 作者名字                        |
| description  | 本子描述                        |
| chineseTeam  | 汉化者                         |
| created_at   | 理论上是创建时间，但是时间对不上，以本子页面的时间为准 |
| finished     | 是否完结                        |
| categories   | 分类                          |
| title        | 本子名字                        |
| tags         | 本子标签                        |
| _id          | 大概是漫画唯一标识符                  |
| likesCount   | 总喜欢数                        |

---

# 个人中心

## 用户信息

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/users/profile",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

### 返回值

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "user": {
      "_id": "***",
      "birthday": "1989-08-13T00:00:00.000Z",
      "email": "***",
      "gender": "m",
      "name": "***",
      "slogan": "1",
      "title": "萌新",
      "verified": false,
      "exp": 220,
      "level": 2,
      "characters": [],
      "created_at": "********",
      "avatar": {
        "originalName": "avatar.jpg",
        "path": "***.jpg",
        "fileServer": "https://storage1.picacomic.com"
      },
      "isPunched": false,
      "character": "https://pica-web.wakamoment.tk/images/***.png"
    }
  }
}
```

| email      | 账号         |
| ---------- | ---------- |
| gender     | 性别（不知道干啥的） |
| name       | 网名         |
| slogan     | 自我介绍       |
| title      | 称号         |
| verified   | 不知道干啥的     |
| characters | 不知道干啥的     |
| created_at | 账号创建时间     |
| isPunched  | 签到状态       |
| character  | 不知道干啥的     |

## 收藏页面

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/users/favourite?s=dd&page=<页数>",
    ":scheme": "https",
    "authorization": "",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

### 返回值

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "comics": {
            "pages": 99,
            "total": 99,
            "docs": [
                {
                    "_id": "***"
                    "title": "***"
                    "author": "***"
                    "totalViews": 99,
                    "totalLikes": 99,
                    "pagesCount": 99,
                    "epsCount": 99,
                    "finished": true,
                    "categories": [
                        "***",
                        "***"
                    ],
                    "thumb": {
                        "originalName": "***.jpg",
                        "path": "***.jpg",
                        "fileServer": "https://storage1.picacomic.com"
                    },
                    "likesCount": 99
                },
                {
                    "_id": "***",
                    "title": "***",
                    "author": "***",
                    "totalViews": 99,
                    "totalLikes": 99,
                    "pagesCount": 99,
                    "epsCount": 99,
                    "finished": true,
                    "categories": [
                        "***"
                    ],
                    "thumb": {
                        "fileServer": "https://storage-b.picacomic.com",
                        "path": "***.jpg",
                        "originalName": "***.jpg"
                    },
                    "likesCount": 99
                }
                ...
            ],
            "page": 99,
            "limit": 99
        }
    }
}
```

| pages                 | 总共有几页                  |
| --------------------- | ---------------------- |
| total                 | 收藏的漫画总数                |
| _id                   | 大概是漫画唯一标识符             |
| title                 | 本子名字                   |
| author                | 作者名字                   |
| totalViews            | 观看数                    |
| totalLikes/likesCount | 总喜欢数                   |
| pagesCount            | 总共有多少页                 |
| epsCount              | 总共有多少篇                 |
| finished              | 是否完结                   |
| categories            | 分类                     |
| originalName          | 不知道是啥，大概率是图片本来的名字，意义不大 |
| path                  | 图片的路径                  |
| fileServer            | 请求地址                   |
| page                  | 当前页数                   |
| limit                 | 一页最多显示多少漫画             |

## 签到

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "POST",
    ":path": "/users/punch-in",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "content-length": "0",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

### 返回值

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "res": {
      "status": "ok",
      "punchInLastDay": "2024-07-29"
    }
  }
}
```

## 伟论

#todo(因为还没有发过言所以不清楚这个到底是有还是没有，暂时作为todo)

## 自我介绍更新

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "PUT",
    ":path": "/users/profile",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "content-type": "application/json; charset=UTF-8",
    "content-length": "16",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

### 请求体

```json
{
  "slogan": "123"
}
```

### 返回值

```json
{
  "code": 200,
  "message": "success"
}
```

## 更新头像

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "PUT",
    ":path": "/users/avatar",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "content-type": "application/json; charset=UTF-8",
    "content-length": "32612",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

### 请求体

```json
{
    "avatar": "data:image/jpeg;base64,<放置base64编码后的图片>"
}
```

### 返回体

```json
{
    "code": 200,
    "message": "success"
}
```

# 本子界面

## 本子详情页

### 本子信息

#### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/comics/<本子id>",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

#### 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "comic": {
            "_id": "66e1b537e50c9326a5f0e6ce",
            "_creator": {
                "_id": "5835b5c17e6d48ce7206576e",
                "gender": "f",
                "name": "喵铃酱",
                "verified": false,
                "exp": 90609,
                "level": 30,
                "role": "knight",
                "characters": [
                    "knight"
                ],
                "title": "萌新",
                "avatar": {
                    "originalName": "avatar.jpg",
                    "path": "e487db6d-6374-4324-8884-a93ad1d26417.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                },
                "slogan": "睡眠不足(＿´Д｀)"
            },
            "title": "もっと激しく！ (月刊Web男の娘・れくしょんッ！S Vol.100)",
            "description": "好色男娘想被侵犯",
            "thumb": {
                "originalName": "image_003.jpg",
                "path": "tobeimg/jZFfosr-2Ray9RpxxiOdVw9p_uyN36vBfnuK4CVQCnk/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlLWIucGljYWNvbWljLmNvbS9zdGF0aWMvZmE0MjE3M2YtMWEyYy00MGRkLTg1NGMtM2U1YTM1ZjM1NGEzLmpwZw.jpg",
                "fileServer": "https://storage-b.picacomic.com"
            },
            "author": "汐焼あゆ",
            "chineseTeam": "瑞树汉化组",
            "categories": [
                "短篇",
                "偽娘哲學"
            ],
            "tags": [
                "偽娘",
                "肛交",
                "肛內中出",
                "雙馬尾"
            ],
            "pagesCount": 18,
            "epsCount": 1,
            "finished": true,
            "updated_at": "2024-09-11T15:20:23.280Z",
            "created_at": "2024-09-11T07:59:33.306Z",
            "allowDownload": true,
            "allowComment": true,
            "totalLikes": 282,
            "totalViews": 24618,
            "totalComments": 28,
            "viewsCount": 24641,
            "likesCount": 282,
            "commentsCount": 28,
            "isFavourite": false,
            "isLiked": false
        }
    }
}
```

| _id                         | 大概是漫画唯一标识符                         |
| --------------------------- | -------------------------------------------- |
| _creator                    | 下方单独说明                                 |
| title                       | 本子名字                                     |
| description                 | 本子介绍                                     |
| originalName                | 不知道是啥，大概率是图片本来的名字，意义不大 |
| path                        | 图片的路径                                   |
| fileServer                  | 请求地址                                     |
| author                      | 作者名字                                     |
| chineseTeam                 | 汉化者                                       |
| categories                  | 分类                                         |
| tags                        | 标签                                         |
| pagesCount                  | 总共有多少页                                 |
| epsCount                    | 总共有多少篇                                 |
| finished                    | 是否完结                                     |
| updated_at                  | 最后更新时间（比UTC-8早一个小时）            |
| created_at                  | 上传时间                                     |
| allowDownload               | 是否允许下载                                 |
| allowComment                | 是否允许评论                                 |
| totalLikes/likesCount       | 喜欢人数                                     |
| totalViews/viewsCount       | 观看量                                       |
| totalComments/commentsCount | 评论总数                                     |
| isFavourite                 | 是否收藏                                     |
| isLiked                     | 是否喜欢                                     |

| _id        | 上传者的唯一标识符，大概 |
| ---------- | ------------ |
| gender     | 上传者性别        |
| name       | 上传者网名        |
| verified   | 优质答案：我不知道    |
| exp        | 上传者经验        |
| level      | 上传者等级        |
| role       | 优质答案：我不知道    |
| avatar     | 上传者头像信息      |
| characters | 优质答案：我不知道    |
| title      | 上传者自我介绍      |

### 本子目录信息

#### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/comics/<本子id>/eps?page=<页数>",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

#### 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "eps": {
            "docs": [
                {
                    "_id": "61d949876570ce4759607749",
                    "title": "杂图17",
                    "order": 25,
                    "updated_at": "2022-01-06T14:26:26.142Z",
                    "id": "61d949876570ce4759607749"
                }
                ...
            ],
            "total": 25,
            "limit": 40,
            "page": 1,
            "pages": 1
        }
    }
}
```

哔咔一次只会加载40篇，继续往下滑的话才会加载剩下的，所以总共要加载`epsCount / 40 + 1`次

## 本子推荐

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/comics/<本子ID>/recommendation",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "1",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

### 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "comics": [
            {
                "_id": "59a04d5d4fdb0f59ee25696b",
                "title": "Admiral!!!!!! (艦隊これくしょん -艦これ-)",
                "author": "HMA (日吉ハナ)",
                "pagesCount": 28,
                "epsCount": 1,
                "finished": true,
                "categories": [
                    "同人",
                    "短篇",
                    "艦隊收藏"
                ],
                "thumb": {
                    "originalName": "IMG_0001.jpg",
                    "path": "tobeimg/Q57qNbwHB6myvJsQNpksnEt_akEp5zVEe_BuMV-7pEo/rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlMS5waWNhY29taWMuY29tL3N0YXRpYy9hMjFmMDUyYS1iZThjLTQxODAtODdkNy0zN2U4YjIzZTM4YWEuanBn.jpg",
                    "fileServer": "https://storage1.picacomic.com"
                },
                "likesCount": 703
            }
            ...
        ]
    }
}
```

懒得写了，对应的值上面基本都写了，这里就不写了，谁要是愿意写也行。

## 本子页面

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/comics/<本子id>/order/<第几篇>/pages?page=1",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "3",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

### 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "pages": {
            "docs": [
                {
                    "_id": "64661f4c2b80b5190554679d",
                    "media": {
                        "originalName": "1.jpg",
                        "path": "tobeimg/....jpg",
                        "fileServer": "https://storage-b.picacomic.com"
                    },
                    "id": "64661f4c2b80b5190554679d"
                }
                ...
            ],
            "total": 34,
            "limit": 40,
            "page": 1,
            "pages": 1
        },
        "ep": {
            "_id": "64661f4c2b80b5190554679c",
            "title": "本間心鈴个人汉化"
        }
    }
}
```

## 喜欢本子

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "POST",
    ":path": "/comics/<本子id>/like",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "3",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "content-length": "0",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

虽然是post，但是没有请求体

### 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "action": "like"
    }
}
```

## 取消喜欢本子

### 请求头

跟上面喜欢一样，懒得写了

### 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "action": "unlike"
    }
}
```

## 收藏本子

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "POST",
    ":path": "/comics/<本子id>/favourite",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "3",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "content-length": "0",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

没有请求体

### 返回值

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "action": "favourite"
    }
}
```

## 取消收藏本子

### 请求头

跟上面一样

### 返回值

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "action": "un_favourite"
    }
}
```

## 本子下载

### 本子下载界面

#### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/comics/<本子id>/eps?page=<页数>",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "1722677958",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

哔咔一次只会加载40篇，继续往下滑的话才会加载剩下的，所以总共要加载`epsCount / 40 + 1`次

#### 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "eps": {
            "docs": [
                {
                    "_id": "5f66256bd18c55467c5ec593",
                    "title": "第44話",
                    "order": 44,
                    "updated_at": "2020-09-19T01:55:03.725Z",
                    "id": "5f66256bd18c55467c5ec593"
                }
                ...
            ],
            "total": 84,
            "limit": 40,
            "page": 2,
            "pages": 3
        }
    }
}
```

### 本子下载

#### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/eps/<本子篇数的id，也就是目录中对应id>/pages?page=<第几篇>",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

#### 请求体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "pages": {
            "docs": [
                {
                    "_id": "601905e007cb4146dc1bf616",
                    "media": {
                        "originalName": "001.jpg",
                        "path": "986609b7-234c-4555-a782-39847fd7be40.jpg",
                        "fileServer": "https://storage1.picacomic.com"
                    }
                }
                ...
            ],
            "total": 66,
            "limit": 40,
            "page": 1,
            "pages": 2
        },
        "ep": {
            "_id": "5f61c84ad18c55467c5a4b90",
            "title": "第1話"
        }
    }
}
```

## 图片下载

### 请求头

```json
{
    ":authority": "###",
    ":method": "GET",
    ":path": "###",
    ":scheme": "https",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

> 注：`authority`还是跟上面的本子图片获取的一样

## 本子评论

### 请求体

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/comics/<本子id>/comments?page=1",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

### 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "comments": {
            "docs": [
                {
                    "_id": "6696201c0f190cd4f1ddb0b6",
                    "content": "刻晴，胡桃，甘雨，芭芭拉，厌战，恶毒，老师的本我都好喜欢！！！",
                    "_user": {
                        "_id": "58417ec6d07271cd66177b94",
                        "gender": "bot",
                        "name": "好名字让绅士取了",
                        "verified": false,
                        "exp": 470,
                        "level": 2,
                        "role": "member",
                        "characters": [],
                        "title": "萌新",
                        "avatar": {
                            "originalName": "avatar.jpg",
                            "path": "tobs/a7523e5f-4eef-4a53-8df7-25788e022e0b.jpg",
                            "fileServer": "https://storage-b.picacomic.com"
                        },
                        "character": "https://pica-web.wakamoment.tk/images/halloween_bot.png"
                    },
                    "_comic": "618234ab8a17d94ea7a0b3a0",
                    "totalComments": 0,
                    "isTop": false,
                    "hide": false,
                    "created_at": "2024-07-16T07:24:12.044Z",
                    "id": "6696201c0f190cd4f1ddb0b6",
                    "likesCount": 0,
                    "commentsCount": 0,
                    "isLiked": false
                }
            ],
            "total": 817,
            "limit": 20,
            "page": "1",
            "pages": 41
        },
        "topComments": [
            {
                "_id": "6185585f1c01ab67be899093",
                "content": "呜呜呜芭芭拉，我的芭芭拉，嘿嘿....嘿嘿.....芭芭拉.....",
                "_user": {
                    "_id": "5a7373a20aefd755e5cc7abb",
                    "gender": "m",
                    "name": "adiossssss",
                    "title": "萌新",
                    "verified": false,
                    "exp": 305,
                    "level": 2,
                    "characters": [],
                    "role": "member",
                    "avatar": {
                        "fileServer": "https://storage1.picacomic.com",
                        "path": "67352678-f430-41e2-a1a6-f8e634f2b846.jpg",
                        "originalName": "avatar.jpg"
                    },
                    "slogan": "null",
                    "character": "https://pica-web.wakamoment.tk/images/halloween_m.png"
                },
                "_comic": "618234ab8a17d94ea7a0b3a0",
                "isTop": true,
                "hide": false,
                "created_at": "2021-11-05T16:14:23.834Z",
                "totalComments": 36,
                "likesCount": 0,
                "commentsCount": 36,
                "isLiked": false
            }
        ]
    }
}
```

不想写了

## 本子评论的评论

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "GET",
    ":path": "/comments/<评论id>/childrens?page=1",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

### 返回值

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "comments": {
            "docs": [
                {
                    "_id": "65e9ddd06b04fdf7b9ea7266",
                    "content": "嗯，舒服了～",
                    "_user": {
                        "_id": "5ec51572d973b665f1b28a82",
                        "gender": "m",
                        "name": "谢泽锋",
                        "title": "萌新",
                        "verified": false,
                        "exp": 340,
                        "level": 2,
                        "characters": [],
                        "role": "member",
                        "avatar": {
                            "originalName": "avatar.jpg",
                            "path": "tobs/fbf192ce-36bf-4813-996b-f55d83e6bb58.jpg",
                            "fileServer": "https://storage-b.picacomic.com"
                        },
                        "slogan": "哼嗯，这样啊…"
                    },
                    "_parent": "6185585f1c01ab67be899093",
                    "_comic": "618234ab8a17d94ea7a0b3a0",
                    "totalComments": 0,
                    "isTop": false,
                    "hide": false,
                    "created_at": "2024-03-07T15:31:28.947Z",
                    "id": "65e9ddd06b04fdf7b9ea7266",
                    "likesCount": 0,
                    "isLiked": false
                }
                ...
            ],
            "total": 36,
            "limit": 5,
            "page": "1",
            "pages": 8
        }
    }
}
```

| total | 一共有多少评论  |
| ----- | -------- |
| limit | 一页加载多少评论 |
| page  | 第几页      |
| pages | 一共几页     |

## 评论本子

#todo

## 举报评论

### 请求头

```json
{
    ":authority": "picaapi.picacomic.com",
    ":method": "POST",
    ":path": "/comments/<评论id>/report",
    ":scheme": "https",
    "authorization": "###",
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": "###",
    "time": "###",
    "nonce": "###",
    "signature": "###",
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": "###",
    "app-platform": "android",
    "app-build-version": "45",
    "content-length": "0",
    "accept-encoding": "gzip",
    "user-agent": "okhttp/3.8.1"
}
```

请求体为空

### 返回体

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "commentId": "***",
        "message": "成功舉報評論"
    }
}
```
