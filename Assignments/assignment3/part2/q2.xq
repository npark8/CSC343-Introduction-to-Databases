declare variable $dataset0 external;
<important>
	{
	let $d := $dataset0/postings
	let $maxV := max(for $s in $d//reqSkill
		let $lev := (data($s/@level) * data($s/@importance))
		return $lev)
	for $rs in $d/posting
	let $mV := max(for $si in $rs//reqSkill
		let $levi := (data($si/@level) * data($si/@importance))
		return $levi)
	where $mV = $maxV
	return $rs
	}
</important>