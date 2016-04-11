_union = (a, b) ->
  r = {}
  for key, val of a
    r[key] = val
  for key, val of b
    r[key] = val
  return r

_reverse = (a) ->
  r = {}
  for key, val of a
    r[val] = key
  return r

class LinkedListNode
  constructor: (@value, @prev, @next) ->

class LinkedList
  constructor: ->
    @head = @tail = null

  push: (value) ->
    unless @head?
      @head = @tail = new LinkedListNode value
    else
      @tail.next = new LinkedListNode value
      @tail.next.prev = @tail
      @tail = @tail.next

  splice: (start, end, replace) ->
    unless replace?
      start.prev.next = end.next
      end.next.prev = start.prev
    else
      if start.prev?
        start.prev.next = replace
        replace.prev = start.prev
      else
        @head = replace
      if end.next?
        end.next.prev = replace
        replace.next = end.next
      else
        @tail = replace
    return

class HeapNode
  constructor: (@index, @value) ->
    @left = @right = null

  meld: (other) ->
    if not other?
      return @

    if @index > other.index
      if Math.random() > 0.5
        @left = other.meld @left
      else
        @right = other.meld @right
      return @
    else
      if Math.random() > 0.5
        other.left = @meld other.left
      else
        other.right = @meld other.right
      return other

class Heap
  constructor: ->
    @root = null; @size = 0

  top: -> @root?.value

  push: (index, value) ->
    @size += 1
    if not @root?
      @root = new HeapNode index, value
    else
      @root = @root.meld new HeapNode index, value

  pop: ->
    @size -= 1
    value = @root.value
    if @root.left?
      @root = @root.left.meld @root.right
    else
      @root = @root.right
    return value

class HuffmanNode
  constructor: (@left, @right) ->
    @count = @left.count + @right.count
    @parent = null
    @left.parent = @; @right.parent = @

  toMap: (prefix = '') -> _union @left.toMap(prefix + '0'), @right.toMap(prefix + '1')

  encode: (str) ->
    map = @toMap()
    return str.split('').map((x) -> map[x]).join ''

  decode: (string) ->
    result = ''
    cursor = @
    for char in string
      if char is '0'
        cursor = cursor.left
      else
        cursor = cursor.right
      if cursor instanceof HuffmanLeaf
        result += cursor.token
        cursor = @
    return result

  leaves: -> @left.leaves().concat @right.leaves()

  leafLevels: (depth = 0) -> @left.leafLevels(depth + 1) + @right.leafLevels(depth + 1)
  serialize: -> "(#{@left.serialize()} #{@right.serialize()})"

class HuffmanLeaf extends HuffmanNode
  constructor: (@token, @count) ->
    @left = @right = @parent = null

  toMap: (prefix) ->
    r = {}; r[@token] = prefix; return r

  leaves: -> [@]

  leafLevels: (depth) -> @token + String.fromCharCode depth
  serialize: -> '\'' + @token

HuffmanLeaf.fromSerialization = (string) ->
  leaves = []
  for char, i in string by 2
    leaf = new HuffmanLeaf char
    leaf._depth = String.charCodeAt i + 1
    maxdepth = Math.max maxdepth, leaf._depth
    leaves.push leaf

  while leaves.length > 1
    leaves.forEach (leaf, next) ->

getHuffmanTree = (counts) ->
  heap = new Heap()
  for key, val of counts
    heap.push -val, new HuffmanLeaf key, val

  while heap.size > 1
    a = heap.pop()
    b = heap.pop()

    newNode = new HuffmanNode a, b
    heap.push -newNode.count, newNode

  return heap.pop()

getCounts = (string) ->
  counts = {}
  for el, i in string
    counts[el] ?= 0
    counts[el] += 1
  return counts

binaryToString = (binary) ->
  str = ''
  for char, i in binary by 8
    str += String.fromCharCode parseInt(binary[i...i + 8], 2)
  return str

stringToBinary = (string) ->
  bin = ''
  for char, i in string
    bin += ('00000000' + string.charCodeAt(i).toString(2))[-8...]
  return bin

compress = (string) ->
  counts = getCounts string
  tree = getHuffmanTree counts
  serializedTree = tree.leafLevels()
  body = tree.encode string
  return serializedTree + '\0\0' + binaryToString(body) + String.fromCharCode(-body.length %% 8)

treeFromSerialization = (string) ->
  list = new LinkedList()
  for char, i in string by 2
    list.push {tree: new HuffmanLeaf(char, 0), depth: string.charCodeAt(i + 1)}
  until list.head is list.tail
    cursor = list.head
    until cursor is list.tail
      if cursor.value.depth is cursor.next.value.depth
        newNode = new LinkedListNode {
          tree: new HuffmanNode(cursor.value.tree, cursor.next.value.tree)
          depth: cursor.value.depth - 1
        }
        list.splice cursor, cursor.next, newNode
        break
      cursor = cursor.next
    if cursor is list.tail
      throw new Error 'Invalid Huffman tree description.'
  return list.head.value.tree

decompress = (string) ->
  length = string.indexOf '\0\0'
  serializedTree = string[...length]
  tree = treeFromSerialization serializedTree
  body = string[length + 2...-1]
  offset = string.charCodeAt string.length - 1
  if offset = 0
    binary = stringToBinary body
  else
    binary = stringToBinary(body)[...-string.charCodeAt(string.length - 1)]
  return tree.decode binary

# USAGE
fs = require 'fs'
argv = require('minimist') process.argv.slice 2

original = fs.readFileSync(argv._[0]).toString()
if argv.x
  result = decompress original
  console.log "Extracted #{original.length} bytes from #{result.length} (factor of #{original.length/result.length})."
else
  result = compress fs.readFileSync(argv._[0]).toString()
  console.log "Compressed #{original.length} bytes to #{result.length} (factor of #{original.length/result.length})."

if argv.o
  fs.writeFileSync argv.o, result
else
  console.log result