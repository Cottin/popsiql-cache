{test} = R = require 'ramda' # auto_require: ramda
{} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ːname, ːsalary, ːtext, ːdate, ːamount] = ['name', 'salary', 'text', 'date', 'amount'] #auto_sugar


DELTA:
	Company1: _ {id: 2},
		projects: _ { ːname},
			entries: _ {ːdate, ːamount, text: {like: 'kidnap'}}

DELTA:
	Company:
		'-1': {id: -1, name: 'test'}
		'3': {id: 3, name: 'Globex Corporation Incorporated'}
		'4': undefined


Company: _ {ːname},
  employees: _ { ːsalary},
    person: _ { ːname}



Company: _ {ːname},
	projects: _ {OR: [{name: {like: 't%'}}, {name: {like: 'e%'}}]}

			# entries: _ {ːdate, ːamount, ːtext}
