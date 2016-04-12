# HELPER FUNCTIONS

# Take two dictionaries and return the dictionary
# that contains the union of their entries
exports.union = (a, b) ->
  r = {}
  for key, val of a
    r[key] = val
  for key, val of b
    r[key] = val
  return r

# Normalize a dictionary of probabilities
exports.normalize = (prob) ->
  total = 0
  for key, val of prob
    total += val

  result = {}
  for key, val of prob
    result[key] = val / total
  return result

# Select a random key from a normalized dictionary
# mapping keys to probabilities
exports.weightedRandom = (prob) ->
  point = Math.random(); total = 0
  for key, val of prob
    total += val
    if total > point then return key
  return null

# Super-simple linked list implementation
# with "splice," for usage in rebuilding
# the tree from serialization
exports.LinkedListNode = class LinkedListNode
  constructor: (@value, @prev, @next) ->

exports.LinkedList = class LinkedList
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

# Heap, implemented as a meldable heap, used
# for constructing the Huffman tree
exports.HeapNode = class HeapNode
  constructor: (@index, @value) ->
    @left = @right = null

  # To meld Heap A with Heap B:
  #   If A or B is empty, return the other.
  #   If root(A) > root(B), then meld root(B) with a random child of root(A)
  #   Otherwise meld root(A) with a random child of root(B)
  #
  # This preserves the heap property at all steps.
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

exports.Heap = class Heap
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

# Utility functions for converting a binary string of '1' and '0'
# to a buffer containing those bits.
exports.binaryToString = (binary) ->
  str = ''
  for char, i in binary by 8
    str += String.fromCharCode parseInt((binary[i...i + 8] + '00000000')[0...8], 2)
  return str

# Opposite function
exports.stringToBinary = (string) ->
  bin = ''
  for char, i in string
    bin += ('00000000' + string.charCodeAt(i).toString(2))[-8...]
  return bin

