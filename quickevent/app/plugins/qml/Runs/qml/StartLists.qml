import QtQml 2.0
import qf.core 1.0
import qf.qmlwidgets 1.0
import Runs 1.0
import "qrc:/qf/core/qml/js/treetable.js" as TreeTable
import "qrc:/qf/core/qml/js/timeext.js" as TimeExt
//import shared.QuickEvent 1.0
import "qrc:/quickevent/js/ogtime.js" as OGTime

QtObject {
	id: root
	property RunsPlugin runsPlugin


	property QfObject internals: QfObject {
		SqlTableModel {
			id: reportModel
		}
	}

	function startListClassesTable(class_filter)
	{
		var event_plugin = FrameWork.plugin("Event");
		var stage_id = runsPlugin.selectedStageId;
		//var stage_data = event_plugin.stageDataMap(stage_id);
		var tt = new TreeTable.Table();

		reportModel.queryBuilder.clear()
			.select2('classes', 'id, name')
			.select2('courses', 'length, climb')
			.from('classes')
			.joinRestricted("classes.id", "classdefs.classId", "classdefs.stageId={{stageId}}")
			.join("classdefs.courseId", "courses.id")
			.orderBy('classes.name');//.limit(1);
		if(class_filter) {
			reportModel.queryBuilder.where(class_filter);
		}
		reportModel.setQueryParameters({stageId: stage_id})
		reportModel.reload();
		tt.setData(reportModel.toTreeTableData());
		tt.setValue("stageId", stage_id)
		tt.setValue("event", event_plugin.eventConfig.value("event"));

		reportModel.queryBuilder.clear()
			.select2('competitors', 'registration')
			.select("COALESCE(competitors.lastName, '') || ' ' || COALESCE(competitors.firstName, '') AS competitorName")
			.select2('runs', 'siId, startTimeMs')
			.from('competitors')
			.joinRestricted("competitors.id", "runs.competitorId", "runs.stageId={{stage_id}}")
			.where("competitors.classId={{class_id}}")
			.orderBy('runs.startTimeMs');
		for(var i=0; i<tt.rowCount(); i++) {
			var class_id = tt.value(i, "classes.id");
			console.debug("class id:", class_id);
			reportModel.setQueryParameters({stage_id: stage_id, class_id: class_id});
			reportModel.reload();
			var ttd = reportModel.toTreeTableData();
			tt.addTable(i, ttd);
		}
		console.debug(tt.toString());
		return tt;
	}

	function startListClubsTable()
	{
		var event_plugin = FrameWork.plugin("Event");
		var stage_id = runsPlugin.selectedStageId;
		var tt = new TreeTable.Table();

		var qs1 = "SELECT * FROM ( SELECT substr(registration, 1, 3) AS clubAbbr FROM competitors) AS t GROUP BY clubAbbr ORDER BY clubAbbr";
		reportModel.query = "SELECT t2.clubAbbr, clubs.name FROM ( " + qs1 + " ) AS t2"
				+ " LEFT JOIN clubs ON t2.clubAbbr=clubs.abbr"
				+ " ORDER BY t2.clubAbbr";
		reportModel.reload();
		tt.setData(reportModel.toTreeTableData());
		tt.setValue("stageId", stage_id)
		tt.setValue("event", event_plugin.eventConfig.value("event"));
		//console.debug(tt.toString());

		reportModel.queryBuilder.clear()
			.select2('competitors', 'registration')
			.select("COALESCE(competitors.lastName, '') || ' ' || COALESCE(competitors.firstName, '') AS competitorName")
			.select2('classes', 'name')
			.select2('runs', 'siId, startTimeMs')
			.from('competitors')
			.joinRestricted("competitors.id", "runs.competitorId", "runs.stageId={{stage_id}}")
			.join("competitors.classId", "classes.id")
			.where("substr(competitors.registration, 1, 3)='{{club_abbr}}'")
			.orderBy('runs.startTimeMs, classes.name');
		for(var i=0; i<tt.rowCount(); i++) {
			var club_abbr = tt.value(i, "clubAbbr");
			console.debug("club_abbr:", club_abbr);
			reportModel.setQueryParameters({club_abbr: club_abbr, stage_id: stage_id});
			reportModel.reload();
			var ttd = reportModel.toTreeTableData();
			tt.addTable(i, ttd);
		}
		return tt;
	}

	function startListStartersTable(class_letter)
	{
		var event_plugin = FrameWork.plugin("Event");
		var stage_id = runsPlugin.selectedStageId;
		//var stage_data = event_plugin.stageDataMap(stage_id);
		var tt = new TreeTable.Table();

		reportModel.queryBuilder.clear()
			.select2('competitors', 'registration')
			.select("COALESCE(competitors.lastName, '') || ' ' || COALESCE(competitors.firstName, '') AS competitorName")
			.select("COALESCE(runs.startTimeMs / 1000 / 60, 0) AS startTimeMin")
			.select2('runs', 'siId, startTimeMs')
			.select2('classes', 'name')
			.from('competitors')
			.joinRestricted("competitors.id", "runs.competitorId", "runs.stageId={{stageId}}")
			.join("competitors.classId", "classes.id")
			.orderBy('runs.startTimeMs, classes.name, competitors.lastName')//.limit(50);
		if(class_letter === 'H') {
			reportModel.queryBuilder.where("classes.name NOT LIKE '" + class_letter + "%'")
		}
		else if(class_letter === 'D'){
			reportModel.queryBuilder.where("classes.name NOT LIKE 'H%'")
		}
		reportModel.setQueryParameters({stageId: stage_id})
		reportModel.reload();
		tt.setData(reportModel.toTreeTableData());
		tt.setValue("stageId", stage_id)
		tt.setValue("event", event_plugin.eventConfig.value("event"));
		//console.warn(tt.toString());
		return tt;
	}

	function nStagesClassesTable(stages_count)
	{
		var event_plugin = FrameWork.plugin("Event");

		var tt = new TreeTable.Table();
		reportModel.queryBuilder.clear()
			.select2('classes', 'id, name')
			.from('classes')
			.orderBy('classes.name');//.limit(1);
		reportModel.reload();
		tt.setData(reportModel.toTreeTableData());
		tt.setValue("stagesCount", stages_count)
		tt.setValue("event", event_plugin.eventConfig.value("event"));

		for(var i=0; i<tt.rowCount(); i++) {
			var class_id = tt.value(i, "classes.id");
			console.debug("class id:", class_id);
			reportModel.queryBuilder.clear()
				.select2('competitors', 'registration, lastName, firstName, siId')
				.select("COALESCE(competitors.lastName, '') || ' ' || COALESCE(competitors.firstName, '') AS competitorName")
				.from('competitors')
				.where("competitors.classId={{class_id}}")
				.orderBy("competitors.lastName, competitors.registration");
			for(var stage_id = 1; stage_id <= stages_count; stage_id++) {
				var runs_table = "runs" + stage_id;
				reportModel.queryBuilder
					.select2(runs_table, "siid, startTimeMs")
					.joinRestricted("competitors.id", "runs.competitorId AS " + runs_table, runs_table + ".stageId=" + stage_id + " AND NOT " + runs_table + ".offRace")
			}
			reportModel.setQueryParameters({class_id: class_id});
			reportModel.reload();
			var ttd = reportModel.toTreeTableData();
			var tt2 = new TreeTable.Table(ttd);
			tt.addTable(i, ttd);
		}
		//console.info(tt.toString());
		return tt;
	}

	function nStagesClubsTable(stages_count)
	{
		var event_plugin = FrameWork.plugin("Event");

		var tt = new TreeTable.Table();
		var qs1 = "SELECT * FROM ( SELECT substr(registration, 1, 3) AS clubAbbr FROM competitors) AS t GROUP BY clubAbbr ORDER BY clubAbbr";
		reportModel.query = "SELECT t2.clubAbbr, clubs.name FROM ( " + qs1 + " ) AS t2"
				+ " LEFT JOIN clubs ON t2.clubAbbr=clubs.abbr"
				+ " ORDER BY t2.clubAbbr";// + " LIMIT 1";
		reportModel.reload();
		tt.setData(reportModel.toTreeTableData());
		tt.setValue("stagesCount", stages_count)
		tt.setValue("event", event_plugin.eventConfig.value("event"));

		for(var i=0; i<tt.rowCount(); i++) {
			var club_abbr = tt.value(i, "clubAbbr");
			//console.debug("class id:", class_id);
			reportModel.queryBuilder.clear()
				.select2('competitors', 'registration, siId')
				.select("COALESCE(competitors.lastName, '') || ' ' || COALESCE(competitors.firstName, '') AS competitorName")
				.select2('classes', 'name')
				.from('competitors')
				.join("competitors.classId", "classes.id")
				.where("substr(competitors.registration, 1, 3)='{{club_abbr}}'")
				.orderBy('classes.name, competitors.lastName');
			for(var stage_id = 1; stage_id <= stages_count; stage_id++) {
				var runs_table = "runs" + stage_id;
				reportModel.queryBuilder
					.select2(runs_table, "siid, startTimeMs")
					.joinRestricted("competitors.id", "runs.competitorId AS " + runs_table, runs_table + ".stageId=" + stage_id + " AND NOT " + runs_table + ".offRace")
			}
			reportModel.setQueryParameters({club_abbr: club_abbr});
			reportModel.reload();
			var ttd = reportModel.toTreeTableData();
			var tt2 = new TreeTable.Table(ttd);
			tt.addTable(i, ttd);
		}
		console.debug(tt.toString());
		return tt;
	}

	function printStartListClasses()
	{
		Log.info("runs printResultsCurrentStage triggered");
		var dlg = runsPlugin.createReportOptionsDialog(FrameWork);
		//var mask = InputDialogSingleton.getText(this, qsTr("Get text"), qsTr("Class mask (use wild cards [*?]):"), "*");
		if(dlg.exec()) {
			var tt = startListClassesTable(dlg.sqlWhereExpression());
			QmlWidgetsSingleton.showReport(runsPlugin.manifest.homeDir + "/reports/startList_classes.qml"
										   , tt.data()
										   , qsTr("Start list by clases")
										   , "printCurrentStage"
										   , {isBreakAfterEachClass: dlg.isBreakAfterEachClass(), isColumnBreak: dlg.isColumnBreak()}
										   );
		}
		dlg.destroy();
		/*
		var w = cReportViewWidget.createObject(null);
		w.windowTitle = qsTr("Start list by clases");
		w.setReport(root.manifest.homeDir + "/reports/startList_classes.qml");
		w.setTableData(tt.data());
		var dlg = FrameWork.createQmlDialog();
		dlg.setDialogWidget(w);
		dlg.exec();
		dlg.destroy();
		*/
	}

	function printStartListClubs()
	{
		Log.info("runs printStartListClubs triggered");
		var tt = startListClubsTable();
		QmlWidgetsSingleton.showReport(runsPlugin.manifest.homeDir + "/reports/startList_clubs.qml", tt.data(), qsTr("Start list by clubs"));
	}

	function printStartListStarters()
	{
		Log.info("runs printStartListStarters triggered");
		var class_letter = InputDialogSingleton.getItem(this, qsTr("Get item"), qsTr("Corridor:"), [qsTr("H"), qsTr("D"), qsTr("All")], 0, false);
		var tt = startListStartersTable(class_letter);
		QmlWidgetsSingleton.showReport(runsPlugin.manifest.homeDir + "/reports/startList_starters.qml", tt.data(), qsTr("Start list for starters"));
	}

	function printClassesNStages()
	{
		Log.info("runs startLists printClassesNStages triggered");
		var event_plugin = FrameWork.plugin("Event");
		var stage_id = event_plugin.currentStageId;
		var n = InputDialogSingleton.getInt(this, qsTr("Get number"), qsTr("Number of stages:"), stage_id, 1, event_plugin.stageCount);
		var tt = nStagesClassesTable(n);
		//console.info("n:", n)
		QmlWidgetsSingleton.showReport(runsPlugin.manifest.homeDir + "/reports/startLists_classes_nstages.qml"
									   , tt.data()
									   , qsTr("Start list by clases")
									   , ""
									   , {stageCount: n});
	}

	function printClubsNStages()
	{
		Log.info("runs startLists printClubsNStages triggered");
		var event_plugin = FrameWork.plugin("Event");
		var stage_id = event_plugin.currentStageId;
		var n = InputDialogSingleton.getInt(this, qsTr("Get number"), qsTr("Number of stages:"), stage_id, 1, event_plugin.stageCount);
		var tt = nStagesClubsTable(n);
		//console.info("n:", n)
		QmlWidgetsSingleton.showReport(runsPlugin.manifest.homeDir + "/reports/startLists_clubs_nstages.qml"
									   , tt.data()
									   , qsTr("Start list by clubs")
									   , ""
									   , {stageCount: n});
	}

	function exportHtmlStartListClasses()
	{
		var default_file_name = "startlist-classes.html";

		var tt1 = startListClassesTable();
		var body = ['body']
		var h1_str = "{{documentTitle}}";
		var event = tt1.value("event");
		if(event.stageCount > 1)
			h1_str = "E" + tt1.value("stageId") + " " + h1_str;
		body.push(['h1', h1_str]);
		body.push(['h2', event.name]);
		body.push(['h3', event.place]);
		body.push(['h3', event.date]);
		var div1 = ['div'];
		body.push(div1);
		for(var i=0; i<tt1.rowCount(); i++) {
			div1.push(['a', {"href": "#class_" + tt1.value(i, 'classes.name')}, tt1.value(i, 'classes.name')], "&nbsp;")
		}
		for(var i=0; i<tt1.rowCount(); i++) {
			div1 = ['h2', ['a', {"name": "class_" + tt1.value(i, 'classes.name')}, tt1.value(i, 'classes.name')]];
			body.push(div1);
			div1 = ['h3', qsTr("length:"), tt1.value(i, 'courses.length'), ' ', qsTr("climb:"), tt1.value(i, 'courses.climb')];
			body.push(div1);
			var table = ['table'];
			body.push(table);
			var tt2 = tt1.table(i);
			var tr = ['tr',
					  ['th', qsTr("Start")],
					  ['th', qsTr("Name")],
					  ['th', qsTr("Registration")],
					  ['th', qsTr("SI")]
					];
			table.push(tr);
			for(var j=0; j<tt2.rowCount(); j++) {
				tr = ['tr'];
				if(j % 2)
					tr.push({"class": "odd"});
				tr.push(['td', OGTime.msecToString_mmss(tt2.value(j, 'startTimeMs'))]);
				tr.push(['td', tt2.value(j, 'competitorName')]);
				tr.push(['td', tt2.value(j, 'registration')]);
				tr.push(['td', tt2.value(j, 'runs.siId')]);
				table.push(tr);
			}
		}
		var file_name = File.tempPath() + "/quickevent/e" + tt1.value("stageId");
		if(File.mkpath(file_name)) {
			file_name += "/" + default_file_name;
			File.writeHtml(file_name, body, {documentTitle: qsTr("Start list by classes")});
			Log.info("exported:", file_name);
			return file_name;
		}
		return "";
	}

	function exportHtmlStartListClubs()
	{
		var default_file_name = "startlist-clubs.html";

		var tt1 = startListClubsTable();
		var body = ['body']
		var h1_str = "{{documentTitle}}";
		var event = tt1.value("event");
		if(event.stageCount > 1)
			h1_str = "E" + tt1.value("stageId") + " " + h1_str;
		body.push(['h1', h1_str]);
		body.push(['h2', event.name]);
		body.push(['h3', event.place]);
		body.push(['h3', event.date]);
		var div1 = ['div'];
		body.push(div1);
		for(var i=0; i<tt1.rowCount(); i++) {
			div1.push(['a', {"href": "#club_" + tt1.value(i, 'clubAbbr')}, tt1.value(i, 'clubAbbr')], "&nbsp;")
		}
		for(var i=0; i<tt1.rowCount(); i++) {
			div1 = ['h2', ['a', {"name": "club_" + tt1.value(i, 'clubAbbr')}, tt1.value(i, 'clubAbbr')]];
			body.push(div1);
			div1 = ['h3', tt1.value(i, 'name')];
			body.push(div1);
			var table = ['table'];
			body.push(table);
			var tt2 = tt1.table(i);
			var tr = ['tr',
					  ['th', qsTr("Start")],
					  ['th', qsTr("Class")],
					  ['th', qsTr("Name")],
					  ['th', qsTr("Registration")],
					  ['th', qsTr("SI")]
					];
			table.push(tr);
			for(var j=0; j<tt2.rowCount(); j++) {
				tr = ['tr'];
				if(j % 2)
					tr.push({"class": "odd"});
				tr.push(['td', OGTime.msecToString_mmss(tt2.value(j, 'startTimeMs'))]);
				tr.push(['td', tt2.value(j, 'classes.name')]);
				tr.push(['td', tt2.value(j, 'competitorName')]);
				tr.push(['td', tt2.value(j, 'registration')]);
				tr.push(['td', tt2.value(j, 'runs.siId')]);
				table.push(tr);
			}
		}
		//var s = JSON.stringify(html, null, 2);
		var file_name = File.tempPath() + "/quickevent/e" + tt1.value("stageId");
		if(File.mkpath(file_name)) {
			file_name += "/" + default_file_name;
			File.writeHtml(file_name, body, {documentTitle: qsTr("Start list by clubs")});
			Log.info("exported:", file_name);
			return file_name;
		}
		return "";
	}

}
