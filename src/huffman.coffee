helper = require './helper.coffee'

# A Huffman tree. A Huffman tree knows its total count,
# its left and right children, how to serialize itself
# and encode or decode a message.
#
# Huffman tree serialization works by listing all the leaf nodes
# in inorder order alongside their depths (e.g. A1B1 to represent the tree
#    .
#   / \
#  A   B
# ). Because Huffman trees
# are always full, this uniquely determines the tree: note that at any moment
# the leftmost two leaves at the same depth must be siblings. Proof:
#
#   Lemma: Every full tree of size >= 2 contains two leaves of the same depth.
#   Proof: The deepest leaf must have a sibling.
#
#   Suppose that the leftmost two leaves A and B at the same depth are not siblings. Then A
#   must be the right child of its parent.
#     .     .
#    / \   /
#   X   A B
#   Consider X, the left sibling of A. If this sibling is a single node, then X and A are the leftmost
#   leaves with the same depth, contradicting our assumption. If not, then X is a tree of size >= 2.
#   By the lemma, it contains two leaves at the same depth, contradicting our assumption.
#
#   Thus A and B must be siblings.
#
# We can therefore reconstruct the tree by simply always combining the leftmost two nodes we see that
# are at the same depth.

exports.HuffmanNode = class HuffmanNode
  # New Huffman tree nodes sum the counts of their children
  constructor: (@left, @right) ->
    @count = @left.count + @right.count
    @parent = null
    @left.parent = @; @right.parent = @

  # Convert to a dictionary for compression
  toMap: (prefix = '') -> helper.union @left.toMap(prefix + '0'), @right.toMap(prefix + '1')

  # Encoding just maps using the dictionary
  encode: (str) ->
    map = @toMap()
    return str.split('').map((x) -> map[x]).join ''

  # To decode, keep a cursor; walk down the tree
  # going left on '0' and right on '1' until you hit a leaf.
  # When you do, output the token at that leaf and reset the cursor
  # to the root.
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

  # Debugging info functions
  leaves: -> @left.leaves().concat @right.leaves()
  lispFormat: -> "(#{@left.serialize()} #{@right.serialize()})"

  # Serialization: serialize all leaf nodes in inorder order and concatenate them.
  serialize: (depth = 0) -> @left.serialize(depth + 1) + @right.serialize(depth + 1)

# A HuffmanLeaf contains the base cases for
# the above described recursive methods in HuffmanNode
exports.HuffmanLeaf = class HuffmanLeaf extends HuffmanNode
  constructor: (@token, @count) ->
    @left = @right = @parent = null

  toMap: (prefix) ->
    r = {}; r[@token] = prefix; return r

  leaves: -> [@]

  serialize: (depth) -> @token + String.fromCharCode depth
  lispFormat: -> '\'' + @token

# Create a HuffmanNode from a given set of otoken counts
# by the standard method -- start with all leaves in a priority queue,
# and keep combining the lowest two trees into a new tree to push
# into the queue.
exports.createHuffmanTree = createHuffmanTree = (counts) ->
  heap = new helper.Heap()
  for key, val of counts
    heap.push -val, new HuffmanLeaf key, val

  while heap.size > 1
    a = heap.pop()
    b = heap.pop()

    newNode = new HuffmanNode a, b
    heap.push -newNode.count, newNode

  return heap.pop()

# Simple method to count token frequencies in a string.
getCounts = (string) ->
  counts = {}
  for el, i in string
    counts[el] ?= 0
    counts[el] += 1
  return counts

# Get a HuffmanNode from its serialization (leaves + depth in inorder order)
# as described above: keep combining the leftmost two nodes with the same depth
# until there is one tree.
exports.fromSerialization = treeFromSerialization = (string) ->
  list = new helper.LinkedList()
  for char, i in string by 2
    list.push {tree: new HuffmanLeaf(char, 0), depth: string.charCodeAt(i + 1)}
  until list.head is list.tail
    cursor = list.head
    until cursor is list.tail
      if cursor.value.depth is cursor.next.value.depth
        newNode = new helper.LinkedListNode {
          tree: new HuffmanNode(cursor.value.tree, cursor.next.value.tree)
          depth: cursor.value.depth - 1
        }
        list.splice cursor, cursor.next, newNode
        break
      cursor = cursor.next

    # If there are no two adjacent children with the same depth, give up.
    if cursor is list.tail
      throw new Error 'Invalid Huffman tree description.'

  return list.head.value.tree

# Compress: get counts, create a huffman tree,
# use the tree to encode the text, serialize the tree
# and append it to the beginning.
exports.compress = (string) ->
  counts = getCounts string
  tree = createHuffmanTree counts
  serializedTree = tree.serialize()
  body = tree.encode string

  # We also need to add a final byte indicating the length of the compressed
  # document modulo 8, so that we don't take extra 0 bits at the end of the last byte.
  #
  # The serialized tree is separated from the rest of the document by the bytes '\0\0'.
  return serializedTree + '\0\0' + helper.binaryToString(body) + String.fromCharCode(-body.length %% 8)

# Decompress: deserialize the tree,
# and use it to decode the rest of the text.
exports.decompress = (string) ->
  # Locate the serialized tree
  length = string.indexOf '\0\0'
  serializedTree = string[...length]

  # Parse it
  tree = treeFromSerialization serializedTree

  # Get the body of the document, and chop
  # its end off according to the final byte.
  body = string[length + 2...-1]
  offset = string.charCodeAt string.length - 1
  if offset is 0
    binary = helper.stringToBinary body
  else
    binary = helper.stringToBinary(body)[..-offset]

  return tree.decode binary
