#!/usr/bin/env coffee

> ./j2f.js
  ./langLi.js
  @u7/retry
  @u7/u8 > u8merge
  @u7/utf8 > utf8e
  @u7/walk
  @u7/sleep
  @u7/wasm-set > BinSet
  @u7/write
  @u7/xxhash3-wasm > hash128
  @u7/yml/Yml.js
  @vitalets/google-translate-api > translate:_translate
  chalk
  fs > existsSync readFileSync
  http-proxy-agent:Agent
  path > dirname join basename
  progress:Bar

translate = retry (args...)=>
  r = await _translate ...args
  await sleep 3e3
  r

{greenBright,gray,yellowBright} = chalk

+ BAR

LANG_LI = [...Object.keys langLi]

{http_proxy} = process.env

OPTION = {}

if http_proxy
  OPTION.fetchOptions = {
    agent:Agent(http_proxy)
  }

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
    # prev
    (v)=>
      r = map[v]
      if not r

        {text:r} = (
          await translate(
            v
            {
              from: from_lang
              to
              ...OPTION
            }
          )
        )
        map[v] = r
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

  BAR.interrupt(
    greenBright(from_lang+' → '+to)+'\n'
  )
  for [k,v] from Object.entries dict
    BAR.tick()
    key_set.delete k
    # 确保被调用过，这样才能保存
    is_ed = ed k,v
    if k of out
      if is_ed
        continue
    out[k] = tv = await tran v
    BAR.interrupt('  '+v + '\n  ' + tv + '\n')
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

translateDir = (dir, from_to)=>
  default_lang = from_to.get()
  from_to.delete()
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
  # 先默认 -> 所有，然后翻译特定语言
  for to from LANG_LI
    if [default_lang,'zh-TW'].includes(to) or CACHED_YML.has to
      continue

    from_lang = from_to.get(to)
    if from_lang
      data = CACHED_YML.get(from_lang)
      if not data
        await translateFromTo dir,default_yml,default_lang,from_lang
        data = yml[from_lang]
        CACHED_YML.set from_lang, data
    else
      from_lang = default_lang
      data = default_yml

    await translateFromTo dir,data,from_lang,to

  zhTw(dir)
  return


< default main = (now)=>

  from_to = new Map

  loop
    dir = dirname now
    if existsSync join now, 'i18n.yml'
      {i18n:conf} = Yml(now)
      for [k,v] from Object.entries(conf)
        if v
          for i from v.split ' '
            from_to.set i, k
        else
          from_to.set undefined, k
      break
    if dir == now
      return
    now = dir

  src = "/i18n/#{from_to.get()}.yml"

  for await fp from walk(
    now
    (d)=>
      ['node_modules','.git'].includes basename d
  )
    if fp.endsWith src
      await translateDir dirname(fp), from_to
  console.log yellowBright '\n❯ i18n end'
  return

