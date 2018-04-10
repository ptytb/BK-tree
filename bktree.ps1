$Global:FuncCalculateLevenshteinDistance = {
    <#
        .SYNOPSIS
        Returns Levenshtein distance of two strings

        .LINK
        https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance
    
        .OUTPUTS
        System.Int32

    #>

    param([string] $word1, [string] $word2)
    
    [int] $len1 = $word1.Length
    [int] $len2 = $word2.Length
    
    $v = [array]::CreateInstance([int], $len1 + 1, $len2 + 1)
    
    [int] $i = 0
    [int] $j = 0

    for ( ; $i -le $len1; $i++) {
        $v[$i, 0] = $i
    }
    
    for ( ; $j -le $len2; $j++) {
        $v[0, $j] = $j
    }
    
    [int] $im1 = 0
    for ($i = 1; $i -le $len1; $i++, $im1++) {
        [int] $rowMin = $i
        [int] $jm1 = 0
        for ($j = 1; $j -le $len2; $j++, $jm1++) {           
            [char] $c1m1 = $word1[$im1]
            [char] $c1m2 = $word1[$i - 2]
            [char] $c2m1 = $word2[$jm1]
            [char] $c2m2 = $word2[$j - 2]

            if ([char]::Equals($c1m1, $c2m1)) {
                [int] $cost = 0
            } else {
                [int] $cost = 1
            }

            [int] $v1 = $v[($im1), $j] + 1  # deletion
            [int] $v2 = $v[$i, ($jm1)] + 1  # insertion
            [int] $v3 = $v[($im1), ($jm1)] + $cost  # subtraction
            
            [int] $v_ij = [Math]::Min([Math]::Min($v1, $v2), $v3)             
            
            if (($i -gt 1) -and ($j -gt 1) -and (
                [char]::Equals($c1m1, $c2m2) -and [char]::Equals($c1m2, $c2m1)
            )) {
                [int] $v4 = $v_ij
                [int] $v5 = $v[($i - 2), ($j - 2)] + $cost
                $v_ij = [Math]::Min($v4, $v5)  # transposition
            }
            
            $rowMin = [Math]::Min($rowMin, $v_ij)
            $v[$i, $j] = $v_ij
        }
    }

    return $v[$len1, $len2]
}

Function Print-Result() {
    for ([int] $i = 0; $i -lt $n; $i++) {
        Write-Host -NoNewline "($i".PadLeft(4)
    }

    Write-Host        

    for ([int] $i = 0; $i -lt $n; $i++) {
        $is_head = $node_offset[$i] -eq -2
        $marker = if ($is_head) { '*' } else { '' }
        Write-Host -NoNewline "$marker$($flat_tree[$i])".PadLeft(4)
    }
        
    Write-Host        

    for ([int] $i = 0; $i -lt $n; $i++) {
        Write-Host -NoNewline "$($distances[$i])".PadLeft(4)
    }

    Write-Host        

    for ([int] $i = 0; $i -lt $n; $i++) {
        Write-Host -NoNewline "$($node_offset[$i])".PadLeft(4)
    }
        
    Write-Host        
    Write-Host
    Write-Host (($this.name_index.Values | ForEach-Object { "$_".PadLeft(10, ' ') }) -join ' ')        
    Write-Host (($this.name_index.Keys | ForEach-Object { "$_".PadLeft(10, ' ') }) -join ' ')        
}

class TreeNode {

	[System.Collections.Generic.Dictionary[[int],[TreeNode]]] $children
	[string] $data

	TreeNode($item) {
        $this.children = [System.Collections.Generic.Dictionary[[int],[TreeNode]]]::new()
        $this.data = $item
	}

	[void] Add($item) {
        if ([string]::IsNullOrEmpty($this.data)) {
            $this.data = $item
            return
        }
        
		[string] $current = $this.data
		[System.Collections.Generic.Dictionary[[int],[TreeNode]]] $_children = $this.children

		while ($true) {
			$dist = & $Global:FuncCalculateLevenshteinDistance $item $current
            $target = $_children[$dist]
            if ($target -eq $null) {
                $_children[$dist] = [TreeNode]::new($item)
                break
            }
            $current = $target.data
            $_children = $target.children
		}
	}

    [System.Collections.ArrayList] Search($item, $radius) {
        $candidates = [System.Collections.Generic.LinkedList[TreeNode]]::new()
        $result = [System.Collections.Generic.List[string]]::new()

        $candidates.Add($this)

        while ($candidates.First -ne $null) {
            $candidate = $candidates.First.Value
            $candidates.RemoveFirst()
            $dist = & $Global:FuncCalculateLevenshteinDistance $item $candidate.data
            if ($dist -le $radius) {
                $result.Add($candidate.data)
            }
            
            $low = $dist - $radius
            $high = $dist + $radius

            foreach ($child in $candidate.children.Keys) {
                if ($child -le $high -and $child -ge $low) {
                    $candidates.Add($candidate.children[$child])
                }
            }
        }

        return $result
    }

}

class BKTree {

    # { Mostly needed to build a faster arrayed indexes
    [TreeNode] $bktree
    [int] $count    
    [System.Collections.Generic.Dictionary[[string],[int]]] $name_index
    # }

    # { For the fast search
    [System.Collections.Generic.Dictionary[[int],[string]]] $index_id_to_name
    [array] $index_flat_tree
    [array] $index_node_offset
    [array] $index_distances
    # }

    BKTree() {
        $this.bktree = [TreeNode]::new('')
        $this.count = 0
        $this.name_index = [System.Collections.Generic.Dictionary[[string],[int]]]::new()
    }

    [void] Add($item) {
        $this.bktree.Add($item)
        $this.name_index[$item] = $this.count
        $this.count++
    }

    [System.Collections.ArrayList] Search($item, $radius) {
        return $this.bktree.Search($item, $radius)
    }

    [void] SaveArrays($FileName) {
        $flat_tree      = [array]::CreateInstance([int], $this.count * 2)
        $node_offset    = [array]::CreateInstance([int], $this.count * 2)
        $distances      = [array]::CreateInstance([int], $this.count * 2)

        $node_indexes   = [System.Collections.Generic.Dictionary[[int],[int]]]::new()
        $n = 0
        
        # Observing all the nodes to flatten the tree
        $nodes = [System.Collections.Generic.LinkedList[TreeNode]]::new()
        $nodes.Add($this.bktree)

        while ($nodes.First -ne $null) {
            $node = $nodes.First.Value
            $nodes.RemoveFirst()

            if ($node.children.Count -gt 0) {
                $current_node = $this.name_index[$node.data]
                $flat_tree[$n] = $current_node
                $node_offset[$n] = -2
                $node_indexes.Add($current_node, $n)

                $n++
            }

            foreach ($child in $node.children.Keys) {
                # Branches which are degenerated into linked lists to be flattened right away
                if ($node.children.Count -eq 1 -and $node.children[1]) {
                    $_node = $node.children[1]
                    while ($_node -ne $null) {
                        $flat_tree[$n] = $this.name_index[$_node.data]
                        $distances[$n] = 1
                        $node_offset[$n] = -1
                        $_node = $_node.children[1]
                        $n++
                    }
                } else {
                    $distances[$n] = $child
                    $current_node = $this.name_index[$node.children[$child].data]
                    $flat_tree[$n] = $current_node
                    $node_offset[$n] = -1  # To be updated at the second pass

                    $n++

                    $nodes.AddLast($node.children[$child])                    
                }
            }
        }

        # Now we know where each node is positioned in the array
        for ([int] $i = 1; $i -lt $n; $i++) {
            $node_id = $flat_tree[$i]
            if ($node_offset[$i] -eq -1 -and $node_indexes.ContainsKey($node_id)) {
                $node_offset[$i] = $node_indexes[$node_id]
            }
        }

        Write-Host "n=$n, n_input=$($this.count), size=$($this.count * 2)"

        #Print-Result
        
        $flat_tree_s      = [array]::CreateInstance([int], $n)
        $node_offset_s    = [array]::CreateInstance([int], $n)
        $distances_s      = [array]::CreateInstance([int], $n)

        [array]::Copy($flat_tree, $flat_tree_s, $n);
        [array]::Copy($node_offset, $node_offset_s, $n);
        [array]::Copy($distances, $distances_s, $n);

        $_index_id_to_name = [System.Collections.Generic.Dictionary[[int],[string]]]::new()
        foreach ($name in $this.name_index.Keys) {
            $id = $this.name_index[$name]
            $_index_id_to_name.Add($id, $name)
        }

        $result = [System.Collections.ArrayList]::new()
        $result.Add($_index_id_to_name)
        $result.Add($flat_tree_s)
        $result.Add($node_offset_s)
        $result.Add($distances_s)

        $fs = New-Object System.IO.FileStream "$FileName", ([System.IO.FileMode]::Create)
        $bf = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
        $bf.Serialize($fs, $result)
        $fs.Close()
    }

    [void] LoadArrays($FileName) {
        $fs = New-Object System.IO.FileStream "$FileName", ([System.IO.FileMode]::Open)
        $bf = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
        $result = $bf.Deserialize($fs)
        $fs.Close()

        $this.index_id_to_name = $result[0]
        $this.index_flat_tree = $result[1]
        $this.index_node_offset  = $result[2]
        $this.index_distances = $result[3]
    }

    [System.Collections.ArrayList] SearchFast([string] $item, [int] $radius) {
        [type] $tuple_t = [System.Tuple[int,int]]
        $candidates = [System.Collections.Generic.LinkedList[System.Tuple[int,int]]]::new()
        $result = [System.Collections.Generic.List[string]]::new()
        [int] $n = $this.index_node_offset.Count        

        $candidates.Add($tuple_t::new(0, 0))

        for (;;) {
            $the_first = $candidates.First
            if ($the_first -eq $null) {
                break
            }

            $candidates.RemoveFirst()
            ([int] $candidate_offset, [int] $candidate_id) = $the_first.Value.Item1, $the_first.Value.Item2

            [string] $candidate_name = $this.index_id_to_name[$candidate_id]
            [int] $dist = & $Global:FuncCalculateLevenshteinDistance $item $candidate_name
            
            if ($dist -le $radius) {
                [void] $result.Add($candidate_name)
            }

            if ($candidate_offset -eq -1) {
                continue
            }
            
            [int] $low = $dist - $radius
            [int] $high = $dist + $radius            
            
            for ([int] $i = $candidate_offset + 1; ; $i++) {
                [int] $child_node_offset = $this.index_node_offset[$i]
                
                if ($child_node_offset -eq -2 -or $i -ge $n) {
                    break
                }

                [int] $child = $this.index_distances[$i]
                if ($child -le $high -and $child -ge $low) {
                    $child_id = $this.index_flat_tree[$i]
                    $candidates.Add( ( $tuple_t::new($child_node_offset, $child_id) ) )
                }
            }

        }

        return $result
    }
}

