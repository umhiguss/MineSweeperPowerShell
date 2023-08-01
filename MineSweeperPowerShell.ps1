Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


function Game ($rows, $columns, $mines){

	$form = New-Object System.Windows.Forms.Form
	$form.StartPosition = 'CenterScreen'
	$form.FormBorderStyle = "FixedSingle"
	$form.ClientSize = New-Object System.Drawing.Size((($columns*25)+20),(($rows*25)+50))
	
	function NewGame {
		$form.Dispose()
		Menu
	}
	
	$newGameButton = New-Object System.Windows.Forms.Button
	$newGameButton.Size = New-Object System.Drawing.Size(75,23)
	$newGameButton.Location = New-Object System.Drawing.Point(10,0)
	$newGameButton.Text = "New Game"
	$newGameButton.add_click({
		NewGame
	})
	$form.Controls.Add($newGameButton)
	
	$minesRemaining = New-Object System.Windows.Forms.Label
	$minesRemaining.Location = New-Object System.Drawing.Point(10, ($form.Height - 60))
	$minesRemaining.Text = "Mines: $mines"
	$form.Controls.Add($minesRemaining)
	
	$global:board = @()
	$global:notMines = ($rows * $columns) - $mines
	function OnClick ($button) {
		if ($board[$button].Enabled) {
			if ($board[$button].Text -eq 'O') {
				$board[$button].Text = ''
				$minesRemaining.Text = $minesRemaining.Text.Replace($minesRemaining.Text.Split(":")[1], ++([int]$minesRemaining.Text.Split(":")[1]))
			}
			# Clicked mine
			$board[$button].Enabled = $false
			if ($board[$button].Tag -eq 'X') {
				$board[$button].BackColor = "Red"
				$board[$button].Text = 'X'
				$board | ForEach-Object {
					$_.Enabled = $false
					if ($_.Tag -eq 'X') {
						$_.Text = 'X'
					}
				}
			}
			else {
				$board[$button].BackColor = "Gray"
				$board[$button].FlatStyle = "Flat"
				$global:notMines--
				Write-Host $notMines
				if ($notMines -eq 0) {
					Write-Host "You win smile"
				}
				if ($board[$button].Tag -ne 0) {
					$board[$button].Text = $board[$button].Tag
				}
				# Clear all surrounding buttons
				else {
					if ($button -lt $columns) {$top = $true} else {$top = $false}
					if ($button -ge (($columns * $rows) - $columns)) {$bottom = $true} else {$bottom = $false}
					if (($button % $columns) -eq 0) {$left = $true} else {$left = $false}
					if (($button % $columns) -eq ($columns - 1)) {$right = $true} else {$right = $false}
					if ($top) {
						# top left corner
						if ($left) {
							OnClick($button+1)
							OnClick($button+$columns)
							OnClick($button+1+$columns)
						}
						# top Right corner
						elseif ($right) {
							OnClick($button-1)
							OnClick($button+$columns)
							OnClick($button-1+$columns)
						}
						# top row
						else {
							OnClick($button+1)
							OnClick($button-1)
							OnClick($button+$columns)
							OnClick($button+1+$columns)
							OnClick($button-1+$columns)
						}
					}
					elseif ($bottom) {
						# bottom left corner
						if ($left) {
							OnClick($button+1)
							OnClick($button-$columns)
							OnClick($button+1-$columns)
						}
						# bottom right corner
						elseif ($right) {
							OnClick($button-1)
							OnClick($button-$columns)
							OnClick($button-1-$columns)
						}
						# bottom row
						else {
							OnClick($button-1)
							OnClick($button+1)
							OnClick($button-$columns)
							OnClick($button-1-$columns)
							OnClick($button+1-$columns)
						}
					}
					elseif ($left) {
						# left row
						OnClick($button+1)
						OnClick($button+$columns)
						OnClick($button+$columns+1)
						OnClick($button-$columns)
						OnClick($button-$columns+1)
					}
					elseif ($right) {
						# right row
						OnClick($button-1)
						OnClick($button+$columns)
						OnClick($button+$columns-1)
						OnClick($button-$columns)
						OnClick($button-$columns-1)
					}
					else {
						# center
						OnClick($button+1)
						OnClick($button-1)
						OnClick($button+$columns)
						OnClick($button+$columns+1)
						OnClick($button+$columns-1)
						OnClick($button-$columns)
						OnClick($button-$columns+1)
						OnClick($button-$columns-1)
					}
				}
			}
		}
	}
	function OnRightClick ($button) {
		if ($board[$button].Text -eq 'O') {
			$newMines = ++([int]$minesRemaining.Text.Split(":")[1])
			$minesRemaining.Text = $minesRemaining.Text.Replace($minesRemaining.Text.Split(":")[1], " $newMines")
			$board[$button].Text = ''
		}
		else {
			$newMines = --([int]$minesRemaining.Text.Split(":")[1])
			$minesRemaining.Text = $minesRemaining.Text.Replace($minesRemaining.Text.Split(":")[1], " $newMines")
			$board[$button].Text = 'O'
		}
	}

	function MakeBoard {
		for ($i = 0; $i -lt $rows; $i++) {
			$row = @()
			for ($j = 0; $j -lt $columns; $j++) {
				$button = New-Object System.Windows.Forms.Button
				$button.Size = New-Object System.Drawing.Size(25, 25)
				$button.Location = New-Object System.Drawing.Point((10+($j*25)), (25+($i*25)))
				$number = ($i*$columns) + $j
				$button.Name = $number
				$button.Tag = 0
				$button.add_click({
					OnClick([int]$this.Name)
				})
				# button doesn't call click on right click so you have to do
				# mouse down or mouse up
				$button.add_mouseup({
					if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
						OnRightClick([int]$this.Name)
					}
					
				})
				$row += $button
			}
			$global:board += $row
		}
		$form.Controls.AddRange($board)	
	}
	MakeBoard

	function CreateMines {
		for ($i = 0; $i -lt $mines; $i++) {
			while ($true) {
				$mineLocation = Get-Random -Maximum ($rows * $columns)
				if ($board[$mineLocation].Tag -eq 0) {
					$board[$mineLocation].Tag = 'X'
					break
				}
			}
		}
	}
	CreateMines
	function IncreaseMineCount($button) {
		$mineCount = [int]$board[$button].Tag
		$mineCount++
		$board[$button].Tag = $mineCount
	}

	function CountMines {
		for ($i = 0; $i -lt $board.Count; $i++) {
			if ($board[$i].Tag -eq 'X') {
				continue
			}
			# Indicates current mine is on a specific edge
			if ($i -lt $columns) {$top = $true} else {$top = $false}
			if ($i -ge (($columns * $rows) - $columns)) {$bottom = $true} else {$bottom = $false}
			if (($i % $columns) -eq 0) {$left = $true} else {$left = $false}
			if (($i % $columns) -eq ($columns - 1)) {$right = $true} else {$right = $false}
			if ($top) {
				# top left corner
				if ($left) {
					if ($board[$i+1].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i+$columns].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i+1+$columns].Tag -eq 'X') {IncreaseMineCount($i)}
				}
				# top Right corner
				elseif ($right) {
					if ($board[$i-1].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i+$columns].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i-1+$columns].Tag -eq 'X') {IncreaseMineCount($i)}
				}
				# top row
				else {
					if ($board[$i-1].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i+1].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i+$columns].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i+1+$columns].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i-1+$columns].Tag -eq 'X') {IncreaseMineCount($i)}
				}
			}
			elseif ($bottom) {
				# bottom left corner
				if ($left) {
					if ($board[$i+1].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i-$columns].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i+1-$columns].Tag -eq 'X') {IncreaseMineCount($i)}
				}
				# bottom right corner
				elseif ($right) {
					if ($board[$i-1].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i-$columns].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i-1-$columns].Tag -eq 'X') {IncreaseMineCount($i)}
				}
				# bottom row
				else {
					if ($board[$i+1].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i-$columns].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i+1-$columns].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i-1-$columns].Tag -eq 'X') {IncreaseMineCount($i)}
					if ($board[$i-1].Tag -eq 'X') {IncreaseMineCount($i)}
				}
			}
			elseif ($left) {
				# left row
				if ($board[$i+1].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i+$columns].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i+$columns+1].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i-$columns].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i-$columns+1].Tag -eq 'X') {IncreaseMineCount($i)}
			}
			elseif ($right) {
				# right row
				if ($board[$i-1].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i+$columns].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i+$columns-1].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i-$columns].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i-$columns-1].Tag -eq 'X') {IncreaseMineCount($i)}
			}
			else {
				# center
				if ($board[$i+1].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i-1].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i+$columns].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i-$columns].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i+$columns+1].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i+$columns-1].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i-$columns+1].Tag -eq 'X') {IncreaseMineCount($i)}
				if ($board[$i-$columns-1].Tag -eq 'X') {IncreaseMineCount($i)}
			}
		}
	}
	CountMines
	
	<#
	$board | ForEach-Object {
		Write-Host -NoNewLine $_.Tag
		if ((([int]$_.Name+1) % $columns) -eq 0) {
			Write-Host
		}
	}
	#>
	$result = $form.ShowDialog()
	$form.Dispose()
}

function Menu {
	$form = New-Object System.Windows.Forms.Form
	$form.StartPosition = 'CenterScreen'
	$form.FormBorderStyle = "FixedSingle"
	$form.ClientSize = New-Object System.Drawing.Size(185,82)
	
	$beginnerButton = New-Object System.Windows.Forms.Button
	$beginnerButton.Size = New-Object System.Drawing.Size(75,23)
	$beginnerButton.Location = New-Object System.Drawing.Point(10,10)
	$beginnerButton.Text = "Beginner"
	$beginnerButton.add_click({
		$form.Dispose()
		Game 9 9 10
	})
	$form.Controls.Add($beginnerButton)
	
	$intermediateButton = New-Object System.Windows.Forms.Button
	$intermediateButton.Size = New-Object System.Drawing.Size(75,23)
	$intermediateButton.Location = New-Object System.Drawing.Point(100,10)
	$intermediateButton.Text = "Intermediate"
	$intermediateButton.add_click({
		$form.Dispose()
		Game 16 16 40
	})
	$form.Controls.Add($intermediateButton)
	
	$expertButton = New-Object System.Windows.Forms.Button
	$expertButton.Size = New-Object System.Drawing.Size(75,23)
	$expertButton.Location = New-Object System.Drawing.Point(55,50)
	$expertButton.Text = "Expert"
	$expertButton.add_click({
		$form.Dispose()
		Game 16 30 99
	})
	$form.Controls.Add($expertButton)
	
	$result = $form.ShowDialog()
	$form.Dispose()
}

Menu