declare variable $dataset0 external;
declare variable $dataset1 external;
<bestskills>
	{
	let $res := $dataset1
	let $it := $dataset0

	for $intr in $it/interviews/interview/assessment
	let $cmpr := (data($intr/communication), data($intr/enthusiasm), data($intr/collegiality))
	let $hi := max($cmpr)
	let $pid := $intr/parent::interview/@pID
	let $fname := for $r in $res/resumes/resume 
			let $x := $r/identification/name/forename
			where $r/@rID = $intr/parent::interview/@rID
			return $x

	return (
			if(data($intr/communication) = $hi) then
			(<best resume = "{data($fname)}" position = "{data($pid)}">
				{$intr/communication}</best>
			)else(),

			if(data($intr/enthusiasm) = $hi) then
			(<best resume = "{data($fname)}" position = "{data($pid)}">
				{$intr/enthusiasm}</best>
			)else(),
	
			if(data($intr/collegiality) = $hi) then
			(<best resume = "{data($fname)}" position = "{data($pid)}">
				{$intr/collegiality}</best>
			)else()
		)
	}
</bestskills>