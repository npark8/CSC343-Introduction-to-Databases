declare variable $dataset0 external;

<qualified>
	{
	let $d := $dataset0
	for $res in $d/resumes/resume
	let $cnt := count($res/skills/skill)
	let $ID := $res/@rID
	where $cnt > 3
	return 
	<candidate rid="{$res/@rID}" numskills="{count($res/skills/skill)}" citizenzhip="{$res/identification/citizenship}">
		<name>{data($res/identification/name/forename)}</name>
	</candidate>
	}
</qualified>