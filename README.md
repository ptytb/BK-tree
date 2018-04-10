# BK-tree

This is a very fast string fuzzy-matching module in written in PowerShell.

It uses *Damerau-Levenshtein* distance as metric function
and *BK-tree* structure to represent a search tree.

*BK-tree* can be flattened into arrays for even faster search.

I wrote this primarily for [pips - Python package browser](https://github.com/ptytb/pips)

# Usage

```PowerShell
Import-Module .\bktree

$bktree = [BKTree]::new()

# Building a BK-tree

$bktree.add('fold')
$bktree.add('mold')
$bktree.add('hold')
$bktree.add('bold')
$bktree.add('fork')
$bktree.add('beer')
$bktree.add('hole')
$bktree.add('shim')

$candidates = $bktree.Search('cold', 2)

# We've built a dictionary, let's save it
$bktree.SaveArrays('dict.bin')

# Load a dictionary
$bktree.LoadArrays('dict.bin')

$candidates = $bktree.SearchFast('cold', 2)
```

Explore and try an example `.\test.ps1` to see it with time measurements.

# Hacking

Uncomment the line `Print-Result` in the `SaveArrays` function to see the internal 
structure of the flattened tree.

In the arrays, node offset `-2` means it is a parent node, `-1` means node has no children.

# Todo

- [ ] Add method switch to return candidates along with distances

# License

Copyright, 2018, Ilya Pronin.
This code is released under the MIT license.
