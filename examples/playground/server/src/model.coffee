{} = R = require 'ramda' # auto_require: ramda
{} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ːDate, ːid〳COUNT, ːID_Int_Seq, ːStr〳, ːInt〳, ːid〳count, ːInt, ːFloat, ːStr, ːsalary〳avg, ːamount〳SUM, ː〳price] = ['Date', 'id〳COUNT', 'ID_Int_Seq', 'Str〳', 'Int〳', 'id〳count', 'Int', 'Float', 'Str', 'salary〳avg', 'amount〳SUM', '〳price'] #auto_sugar

popsiql = require '../../../../../popsiql/src/popsiql'

_ = (...xs) -> xs


module.exports = popsiql.model.createModel

	$config:
		entityToTable: 'pascalToSnake'
		propToCol: 'camelToSnake'

	Company:
		id: ːID_Int_Seq
		name: ːStr
		turnover: ːInt

		projects: {oneToMany〳: 'Company.id = Project.companyId'}
		employees: {oneToMany〳: 'Company.id = Employment.companyId'}

		numEmployees: {employees: _ {ːid〳COUNT}}
		# select count(id), "companyId" from employment where "companyId" in (1,2) group by "companyId"
		managers: {employees: _ {position: 'Manager'}}
		# select salary, "companyId" from employment where "companyId" in (1,2) and "position" ilike '%manager%'
		#1 richManagers: {managers: _ {salary: {gt: 1000000}}}
		#1 numRichManagers: {richManagers: _ {ːid〳COUNT}}
		# femaleEmployees: {employees: _ {person〳sex: 'F'}}
		# numFemaleEmployees: {femaleEmploees: _ {ːid〳count}}

		# importantEmployees2: {emplyees: _ {salary: {gt: 'FORM $turnover / $numEmployees'}}}
		# importantEmployees3: {emplyees: _ {salary: {gt: '= $turnover / $numEmployees'}}}

		importantEmployees: ({turnover, numEmployees, managers: {personId}}) ->
			avgEmpTurnover = turnover / numEmployees
			{employees: _ {salary: {gt: avgEmpTurnover}}}

		hoursByEmployee: ({employees: {personId}}) ->
			{WorkEntry: _ {ːamount〳SUM, personId〳GROUP1: {in: personId}}}

		hoursByManager: ({managers: {personId}}) ->
			{WorkEntry: _ {ːamount〳SUM, personId〳GROUP1: {in: personId}}}

		# importantEmployees: ({turnover, numEmployees}) ->
		# 	{employees: _ {salary: {gt: "#{turnover} / #{numEmployees}"}}}


		numImportantEmployees: {importantEmployees: _ {ːid〳COUNT}}

		# realations Company.id = Project.companyId
		# simple conditions position: 'Manager'
		# child conditions person〳sex: 'F'
		# parent field conditions ({connectionTypeId, capacityId, serviceLevelId}) -> 
		# sibling subs conditions ({turnover, numEmployees}) -> 



		# numEmployees: {VALUE: {employees: _ {ːid〳COUNT}}}
		# # select count(id), "companyId" from employment where "companyId" in (1,2) group by "companyId"
		# managers: {Memployees: _ {position: 'Manager'}}
		# # select salary, "companyId" from employment where "companyId" in (1,2) and "position" ilike '%manager%'
		# richManagers: {managers: _ {salary: {gt: 1000000}}}
		# numRichManagers: {richManagers: _ {ːid〳COUNT}}


		# price: ({connectionTypeId, capacityId, serviceLevelId}) ->
		# 	Price: _ {connectionTypeId, capacityId, serviceLevelId, ː〳price}

		# importantEmployees: ({turnover, employees}) ->
		# 	avgEmpTurnover = turnover / numEmployees
		# 	{employees: _ {salary: {gt: avgEmpTurnover}}}


		# numImportantEmployees: {importantEmployees: _ {ːid〳COUNT}}

		# femaleEmployees: {employees: _ {person〳sex: 'F'}}
		# noFemaleEmployees: {femaleEmploees: _ {ːid〳count}}
		# noWomen: {employees: _ {person〳sex: 'F', ːid〳count}}
		# noMen: {employees: _ {person〳sex: 'M', ːid〳count}}

		# avgSalary: {employees: _ {ːsalary〳avg}}
		# avgSalaryWomen: {employees: _ {person〳sex: 'M', ːsalary〳avg}}
		# avgSalaryMen: {employees: _ {person〳sex: 'F', ːsalary〳avg}}


	Person:
		id: ːID_Int_Seq
		name: ːStr
		sex: ːStr
		age: ːInt

		roles: {oneToMany〳: 'Person.id = Role.personId'}
		entries: {oneToMany〳: 'Person.id = WorkEntry.personId'}

	Employment:
		id: ːID_Int_Seq
		person: {oneToOne: 'Employment.personId = Person.id'}
		company: {manyToOne: 'Employment.companyId = Company.id'}
		position: ːStr
		salary: ːInt

	Project:
		id: ːID_Int_Seq
		name: ːStr
		type: ːStr
		price: ːInt〳
		dueDate: ːDate

		company: {manyToOne: 'Project.companyId = Company.id'}
		roles: {oneToMany〳: 'Project.id = Role.projectId'}
		entries: {oneToMany〳: 'Project.id = WorkEntry.projectId'}

		# lateEntries: ({dueDate}) ->
		# 	{entries: _ {date: {gt: dueDate}}}

	Role:
		id: ːID_Int_Seq
		name: ːStr

		person: {manyToOne: 'Role.personId = Person.id'}
		project: {manyToOne: 'Role.projectId = Project.id'}

	Task:
		id: ːID_Int_Seq
		name: ːStr

		entries: {oneToMany〳: 'Task.id = WorkEntry.taskId'}

	WorkEntry:
		id: ːID_Int_Seq
		date: ːDate
		amount: ːFloat
		text: ːStr〳

		person: {manyToOne: 'WorkEntry.personId = Person.id'}
		task: {manyToOne: 'WorkEntry.taskId = Task.id'}
		project: {manyToOne: 'WorkEntry.projectId = Project.id'}











