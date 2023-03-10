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
    md:(root, file, LANG_LI)=>
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

  default_src = to_from.get(default_lang) or default_lang

  for await fp from walk(
    now
    (d)=>
      ['node_modules','.git'].includes basename d
  )
    rfp = fp[now_len..]
    dir = dirname(fp)

    if fp[dir.length+1..] == default_src+'.yml'
      pos = rfp.indexOf('/i18n/')
      if pos < 0
        pos = rfp.indexOf('.i18n/')

      if pos > 0
        pos += 6
        console.log yellowBright "\n❯ #{dir} translate begin"
        await translateYmlDir dir, to_from, default_lang
        await hook.yml dir, default_lang
        console.log gray "❯ #{dir} translated\n"
    else if fp.endsWith('.md')
      lang_fp = '/'+default_src+'/'
      pos = rfp.indexOf lang_fp
      if pos > 0
        workdir = now + rfp.slice(0, pos+1)
        file = rfp.slice(pos+lang_fp.length)
        tran = (src, to)=>
          args = [workdir, file, src, to]
          await translateMd ...args
          return
        if default_src != default_lang
          await tran(default_src, default_lang)
        for i from LANG_LI
          if i != default_lang and i!=default_src
            if i == 'zh-TW'
              src = 'zh'
            else
              src = to_from.get(i) or default_lang
            await tran(src,i)
        hook.md(
          workdir
          file
          LANG_LI
        )

  return

