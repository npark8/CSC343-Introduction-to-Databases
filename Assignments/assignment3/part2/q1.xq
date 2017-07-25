declare variable $dataset0 external;
<dbjobs>
	{
	let $d := $dataset0/postings/posting[reqSkill[@level="5"]/@what="SQL"]
	return $d
	}
</dbjobs>