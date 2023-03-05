#!/usr/bin/env coffee

> fs > existsSync
  path > dirname join basename
  ./yml.js > translateYmlDir
  ./md.js > translateMd
  @u7/yml/Yml.js
  get_default:
  ./LANG_LI.js
  @u7/walk
  chalk

{gray,yellowBright} = chalk

< default main = (
  now
  hook={
    yml:(dir, default_lang)=>
    md:(root, workdir, file, lang, to)=>
  }
)=>

  to_from = new Map
  from_to = new Map

  loop
    dir = dirname now
    if existsSync join now, 'i18n.yml'
      {i18n:conf} = Yml(now)
      for [k,v] from Object.entries(conf)
        if v
          for i from v.split ' '
            to_from.set i, k
            from_to.get_default(k,[]).push i
        else
          to_from.set undefined, k
      break
    if dir == now
      return
    now = dir

  default_lang = to_from.get()
  to_from.delete()

  li = from_to.get 'zh'
  if li
    li.push 'zh-TW'
  to_lang = new Set()
  for li from from_to.values()
    for i from li
      to_lang.add i

  now_len = now.length

  traned_default = new Set()

  for await fp from walk(
    now
    (d)=>
      ['node_modules','.git'].includes basename d
  )
    rfp = fp[now_len..]
    dir = dirname(fp)
    pos = rfp.indexOf('/i18n/')
    if pos < 0
      pos = rfp.indexOf('.i18n/')

    if ~ pos
      if fp[dir.length+1..] == default_lang+'.yml'
        console.log yellowBright "\n❯ #{dir} translate begin"
        await translateYmlDir dir, to_from, default_lang
        await hook.yml dir, default_lang
        console.log gray "❯ #{dir} translated\n"
      else if fp.endsWith('.md')
        pos += 6
        root = now + rfp.slice(0,pos)
        file = basename(rfp)
        lang = basename(dirname(rfp))
        workdir = rfp.slice(pos,rfp.length-lang.length-file.length-1)

        tran = (src, to)=>
          args = [root, workdir, file, src, to]
          await translateMd ...args
          hook.md ...args
          return

        key = workdir+file.slice(0,-3)

        if not traned_default.has key
          src = to_from.get(default_lang)
          if src
            await tran(src, default_lang)
          traned_default.add key

        if lang == default_lang
          for i from LANG_LI
            if src == i
              continue
            if not to_lang.has i
              await tran(lang, i)
        else
          li = from_to.get lang
          if li
            for i from li
              if i == default_lang
                continue
              await tran(lang, i)

  return

