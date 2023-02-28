> @u7/read
  @u7/snake
  @u7/uridir
  @u7/write
  # @u7/zipint > zip
  # @u7/blake3 > Blake3
  # @u7/hashid > HashId
  # radix-64:radix64
  @u7/utf8 > utf8e
  @u7/u8 > u8merge
  @u7/yml/Yml.js
  fs > existsSync readFileSync
  path > join dirname basename resolve
  ./LANG_LI.js

# {encodeInt} = radix64()

outFp = (dir,name)=>
  join dir, name

outJs = (dir, name)=>
  join dir, name+'.js'

code_js = (dir, js_dir, lang)=>
  code_fp = outJs js_dir, 'code'

  code = if existsSync code_fp then await import(resolve code_fp) else {}

  id = 0
  for [k,v] from Object.entries code
    if v >= id
      id = v + 1

  out = []

  k_code = []
  for [key,v] from Object.entries lang
    k = snake(key).toLocaleUpperCase()
    i = code[k]

    # 0 是有效的id
    if i == undefined
      i = id++

    k_code.push [key,i]
    out.push [
      k
      i
    ]

  out.sort (a,b)=>
    a[1] - b[1]

  for [k,v],pos in out
    out[pos] = "#{k}=#{v}"

  write(code_fp, 'export const '+out.join(',')+';')
  return k_code

push = (li, n, pre)=>
  {length} = li
  if length
    li.push n - pre - 1
  else
    li.push n
  return

export default (dir, js_dir, bin_dir, default_lang='en')=>
  yml = Yml(dir)
  lang = yml[default_lang]

  li = await code_js(dir, js_dir, lang)

  pos_li = []
  pre_pos = 0
  id_li = []

  pre_id = -1
  + pre_push_id
  pre_pos = -1

  for [i,id],pos in li
    if id != pre_id+1
      push pos_li, pos, pre_pos
      push id_li, id, pre_push_id
      pre_pos = pos
      pre_push_id = id
    pre_id = id

  pos_id_li = pos_li.concat(id_li)
  write(
    outJs(js_dir, 'posId')
    'export default '+JSON.stringify(pos_id_li)
  )
  #blake3 = new Blake3
  #blake3.update zip pos_id_li

  onMount = outJs js_dir, 'onMount'
  pkg = basename(dirname dir)
  if not existsSync onMount
    write(
      onMount
      """\
      import posId from './posId.js'
      import i18n from "../../i18n.js"
      import ver from "./ver.js"
      export default i18n.#{pkg}(ver, posId)
      """
    )

  for lang from LANG_LI
    t = []
    d = yml[lang]
    for [key] in li
      t.push(
        utf8e(d[key])
      )
      t.push new Uint8Array(1)
    bin = u8merge(...t)[..-2]
    write(
      join bin_dir, lang
      bin
    )


    # blake3.update bin

  #hash = blake3.finalize()

  #fp = outFp js_dir, '.hash'
  #if existsSync fp
  #  hashid = HashId.load readFileSync fp
  #  id = hashid.get hash
  #  if undefined == id
  #    id = hashid.maxId()+1
  #else
  #  hashid = new HashId
  #  id = 0

  #console.log 'ver',id

  #hashid.set hash, id
  #write(
  #  fp
  #  hashid.dump()
  #)
  ver = outJs js_dir, 'ver'
  if not existsSync ver
    write ver, "export default '-'"
  return
