#!/usr/bin/env coffee

> ./j2f.js
  ./LANG_LI.js
  ./defrag.js
  ./tran.js > tranHtml
  @u7/u8 > u8merge
  @u7/utf8/utf8e.js
  @u7/sleep
  @u7/wasm-set > BinSet
  @u7/write
  @u7/xxhash3-wasm > hash128
  @u7/yml/Yml.js
  chalk
  fs > existsSync readFileSync
  path > join
  progress:Bar

{greenBright,gray} = chalk

+ BAR

translated = (dir, from_lang, to)=>
  key = ".i18n/ed/#{from_lang}.#{to}"
  fp = join dir, key

  if existsSync fp
    pre = BinSet.load(
      readFileSync fp
      16
    )
  else
    pre = new BinSet

  now = new BinSet
  [
    # prev
    (k,v)=>
      kv = hash128 u8merge(
        utf8e(k)
        new Uint8Array([0])
        utf8e(v)
      )
      now.add kv
      return pre.has kv

    # save
    =>
      write(
        fp
        now.dump()
      )
      return

  ]

translateWord = (yml, from_lang, to)=>
  key = ".i18n/cache/#{from_lang}.#{to}"
  map = yml[key] or {}
  [
    # translate
    (out, kv_li)=>
      if not kv_li.length
        return

      kli = []
      to_transalte = []
      for [k,v] from kv_li
        r = map[v]
        if r == undefined
          kli.push k
          to_transalte.push v

      console.log greenBright(from_lang+' → '+to)
      n = 0
      for await i from (
        tranHtml(
          to_transalte
          to
          from_lang
        )
      )
        v = to_transalte[n]

        i = defrag to, i, v

        k = kli[n++]
        BAR.interrupt('  ' + v + ' → ' + i)
        out[k] = map[v] = i
      r

    # save
    (set)=>
      for i from Object.keys map
        if not set.has i
          delete map[i]
      yml[key] = map
      return
  ]

translateFromTo = (dir, dict, from_lang, to)=>
  yml = Yml dir
  out = yml[to] or {}
  [tran, save_word] = translateWord(yml, from_lang, to)
  [ed, save_ed] = translated dir, from_lang, to

  key_set = new Set Object.keys out
  val_set = new Set Object.values dict

  to_transalte = []

  for [k,v] from Object.entries dict
    BAR.tick()
    key_set.delete k
    # 确保被调用过，这样才能保存
    is_ed = ed k,v
    if k of out
      if is_ed
        continue
    to_transalte.push [k,v]

  await tran out, to_transalte

  for i from key_set
    delete out[i]
  yml[to] = out
  save_word(val_set)
  save_ed()
  return

zhTw = (dir)=>
  yml = Yml(dir)
  out = {}
  for [k,v] from Object.entries yml.zh
    out[k] = j2f v
  yml['zh-TW'] = out
  return

CACHED_YML = new Map

< translateYmlDir = (dir, to_from, default_lang)=>
  yml = Yml(dir)
  default_yml = yml[default_lang]

  BAR = new Bar(
    ':percent :bar :current/:total COST :elapseds ETA :etas'
    {
      total : Object.keys(default_yml).length*(LANG_LI.length-1)
      complete: '━'
      incomplete: gray '─'
    }
  )

  src = to_from.get(default_lang)
  if src
    await translateFromTo dir,  yml[src], src, default_lang

  # 先默认 -> 所有，然后翻译特定语言
  for to from LANG_LI
    if [default_lang,'zh-TW',src].includes(to) or CACHED_YML.has to
      continue

    from_lang = to_from.get(to)
    if from_lang
      data = CACHED_YML.get(from_lang)
      if not data
        if from_lang != src
          await translateFromTo dir,default_yml,default_lang,from_lang
        data = yml[from_lang]
        CACHED_YML.set from_lang, data
    else
      from_lang = default_lang
      data = default_yml

    await translateFromTo dir,data,from_lang,to

  zhTw(dir)
  CACHED_YML.clear()
  return

