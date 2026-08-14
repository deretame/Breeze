================================================================================
rquickjs_playground vs Node.js WPT fetch 差距分析
================================================================================

差距最大的文件（Node 通过率高 - Rust 通过率高，降序）：
文件                                                               Δ通过率         Rust         Node
fetch/api/request/request-init-contenttype.any.js               11.1%  16/ 18  18/ 18
fetch/api/response/response-init-contenttype.any.js             11.1%  16/ 18  18/ 18
fetch/api/basic/header-value-combining.any.js                    0.0%  0/  6  0/  6
fetch/api/basic/header-value-null-byte.any.js                    0.0%  1/  1  1/  1
fetch/api/basic/historical.any.js                                0.0%  3/  3  3/  3
fetch/api/basic/request-head.any.js                              0.0%  1/  1  1/  1
fetch/api/basic/request-headers-case.any.js                      0.0%  0/  2  0/  2
fetch/api/basic/request-headers-nonascii.any.js                  0.0%  0/  1  0/  1
fetch/api/basic/response-null-body.any.js                        0.0%  1/ 11  1/ 11
fetch/api/body/formdata.any.js                                   0.0%  3/  3  3/  3
fetch/api/body/mime-type.any.js                                  0.0%  20/ 20  20/ 20
fetch/api/headers/header-values-normalize.any.js                 0.0%  1/ 62  1/ 62
fetch/api/headers/headers-basic.any.js                           0.0%  23/ 23  23/ 23
fetch/api/headers/headers-casing.any.js                          0.0%  4/  4  4/  4
fetch/api/headers/headers-combine.any.js                         0.0%  6/  6  6/  6
fetch/api/headers/headers-errors.any.js                          0.0%  18/ 18  18/ 18
fetch/api/headers/headers-normalize.any.js                       0.0%  3/  3  3/  3
fetch/api/headers/headers-record.any.js                          0.0%  13/ 13  13/ 13
fetch/api/headers/headers-structure.any.js                       0.0%  8/  8  8/  8
fetch/api/request/forbidden-method.any.js                        0.0%  6/  6  6/  6


按 Rust 失败数排序（绝对数量大的短板）：
文件                                                                失败数         Rust         Node
fetch/api/headers/header-values-normalize.any.js                  61  1/ 62  1/ 62
fetch/api/basic/response-null-body.any.js                         10  1/ 11  1/ 11
fetch/api/basic/header-value-combining.any.js                      6  0/  6  0/  6
fetch/api/request/request-init-priority.any.js                     3  5/  8  2/  8
fetch/api/response/response-init-contenttype.any.js                2  16/ 18  18/ 18
fetch/api/basic/request-headers-case.any.js                        2  0/  2  0/  2
fetch/api/request/request-init-contenttype.any.js                  2  16/ 18  18/ 18
fetch/api/basic/request-headers-nonascii.any.js                    1  0/  1  0/  1
fetch/api/headers/headers-no-cors.any.js                           1  7/  8  0/  8
fetch/api/headers/headers-structure.any.js                         0  8/  8  8/  8
fetch/api/request/request-consume-empty.any.js                     0  14/ 14  0/ 14
fetch/api/body/mime-type.any.js                                    0  20/ 20  20/ 20
fetch/api/headers/headers-combine.any.js                           0  6/  6  6/  6
fetch/api/basic/header-value-null-byte.any.js                      0  1/  1  1/  1
fetch/api/headers/headers-casing.any.js                            0  4/  4  4/  4
fetch/api/headers/header-setcookie.any.js                          0  24/ 24  23/ 24
fetch/api/headers/headers-record.any.js                            0  13/ 13  13/ 13
fetch/api/request/request-headers.any.js                           0  61/ 61  0/ 61
fetch/api/response/response-static-error.any.js                    0  2/  2  2/  2
fetch/api/response/response-static-redirect.any.js                 0  11/ 11  11/ 11


主要缺失类别估算：
  Headers 校验/规范化/合并/guard                       Rust 失败  10  |  Node 失败 151
  Response 静态方法与初始化校验                           Rust 失败   0  |  Node 失败   0
  Request/Response body MIME 类型与 Content-Type   Rust 失败   4  |  Node 失败   8
  body 消费方法 (formData/text/arrayBuffer/blob/json/clone) Rust 失败   0  |  Node 失败  33
  浏览器全局对象缺失 / 需要服务器                             Rust 失败  71  |  Node 失败 154
  Request 属性/结构不符合规范                            Rust 失败   3  |  Node 失败   6
