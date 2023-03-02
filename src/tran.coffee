#!/usr/bin/env coffee

> @u7/req > reqJson
  http-proxy-agent:Agent
  node-fetch:fetch

global.fetch = fetch

{http_proxy} = process.env

OPTION = {}
if http_proxy
  OPTION.agent = Agent(http_proxy)

_tran = (url, q_li, to_lang, from_lang)=>
  url += "&tl=#{to_lang}"
  if from_lang
      url+="&sl=#{from_lang}"
  reqJson(
    url
    {
      headers: {
        "content-type": "application/x-www-form-urlencoded",
      },
      body: q_li.map((i) => "q=" + encodeURIComponent(i)).join("&"),
      method: "POST",
      ...OPTION
    },
  )

LIMIT = 10000

tran = (url, q_li, to_lang, from_lang)->
  if not q_li.length
    return []

  li = []
  for i from q_li
    li.push i.length
  li.push LIMIT

  pre = 0
  c = li[0]

  t = []

  t_tran = =>
    _tran(url, t, to_lang, from_lang)

  for i,pos in q_li
    t.push i
    next = li[pos+1]
    c += next
    if c > LIMIT
      c = next
      yield from await t_tran()
      t = []

  return


API = "https://translate.google.com/translate_a/t?client=gtx&sr=1&v=1.0"

export tranHtml = tran.bind tran,API + '&format=html'

export tranText = tran.bind tran,API

if process.argv[1] == decodeURI (new URL(import.meta.url)).pathname
  li = ['<strong>Bok kaj ima? </strong><br Ready><br Good><br Left><br Center>']

  for t from [tranText,tranHtml]
    for await i from t(
      li
      'sr'
      'hr'
    )
      console.log i
  process.exit()

