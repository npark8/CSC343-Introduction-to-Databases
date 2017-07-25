declare variable $dataset0 external;
declare variable $dataset1 external;
<histogram>
{
	let $r := $dataset1/resumes/resume
	let $p := $dataset0
	for $skl in distinct-values($p/postings/posting/reqSkill/@what)
	return
	<skill name="{$skl}">
	{
		for $lvl in 1 to 5	
		return
		<count level="{$lvl}" n="{count(for $nres in $r where $nres[skills/skill[@level = $lvl]/@what = $skl] return $nres)}"/>
	}
	</skill>
}
</histogram>