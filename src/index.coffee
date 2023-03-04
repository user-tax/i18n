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

  from_to = new Map
  to_from = new Map

  loop
    dir = dirname now
    if existsSync join now, 'i18n.yml'
      {i18n:conf} = Yml(now)
      for [k,v] from Object.entries(conf)
        if v
          for i from v.split ' '
            from_to.set i, k
            to_from.get_default(k,[]).push i
        else
          from_to.set undefined, k
      break
    if dir == now
      return
    now = dir

  default_lang = from_to.get()
  from_to.delete()

  li = to_from.get 'zh'
  if li
    li.push 'zh-TW'
  to_lang = new Set()
  for li from to_from.values()
    for i from li
      to_lang.add i

  now_len = now.length

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
        await translateYmlDir dir, from_to, default_lang
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

        if lang == default_lang
          src = from_to.get(default_lang)
          if src
            await tran(src, default_lang)

          for i from LANG_LI
            if src == i
              continue
            if not to_lang.has i
              await tran(lang, i)
        else
          li = to_from.get lang
          if li
            for i from li
              if i == default_lang
                continue
              await tran(lang, i)

  return

