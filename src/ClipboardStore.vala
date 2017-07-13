/*
* Copyright (c) 2017 David Hewitt (https://github.com/davidmhewitt)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: David Hewitt <davidmhewitt@gmail.com>
*/

public class Clipped.ClipboardStore : Object {
    private bool database_ready = false;
    private string db_location;
    private Sqlite.Database db;

    public enum ClipboardEntryType {
        TEXT
    }

    public struct ClipboardEntry {
        int id;
        ClipboardEntryType type;
        DateTime date_copied;
        string text;
        string application_id;
        string application_name;
        string optional_uri;
        int optional_int;
    }
 
    public ClipboardStore () {
        var config_dir_path = Path.build_path (Path.DIR_SEPARATOR_S, Environment.get_user_config_dir(), "clipped");
        var config_dir = File.new_for_path (config_dir_path);
        if (!config_dir.query_exists ()) {
            config_dir.make_directory_with_parents ();
        }
        
        db_location = Path.build_path (Path.DIR_SEPARATOR_S, config_dir_path, "ClipboardStore.sqlite");
        if (File.new_for_path (db_location).query_exists ()) {
            open_database ();
        } else {
            open_database ();
            prepare_database ();
        }
    }
    
    private bool open_database () {
        int ec = Sqlite.Database.open(db_location, out db);
        if(ec != Sqlite.OK) {
            critical ("Unable to create/open database at %s", db_location);
            return false;
        } else {
            return true;
        }
    }

    private void prepare_database () {
        string query = """
            CREATE TABLE entry (
                type                INT         NOT NULL,
                date_copied         DATETIME    NOT NULL    DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW', 'localtime')),
                last_used           DATETIME    NOT NULL    DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW', 'localtime')),
	            text	            TEXT,
                application_id      TEXT,
                application_name    TEXT,
	            optional_uri        TEXT,
                optional_int        INTEGER,
                checksum            STRING      NOT NULL,
                UNIQUE (checksum)
            );
            """;
        string error_message;
        int ec = db.exec (query, null, out error_message);
        if(ec != Sqlite.OK) {
            critical ("Unable to create tables in database. Error: %s", error_message);
        }
    }

    public void insert_text_item (string text) {
        var checksum = Checksum.compute_for_string (ChecksumType.SHA1, text);
        Sqlite.Statement stmt;

	    const string prepared_query_str = "INSERT OR IGNORE INTO entry (type, text, checksum) VALUES (0, $TEXT, $CHECKSUM);";
	    int ec = db.prepare_v2 (prepared_query_str, prepared_query_str.length, out stmt);
	    if (ec != Sqlite.OK) {
		    warning ("Error inserting clipboard entry: %s\n", db.errmsg ());
		    return;
	    }

	    int param_position = stmt.bind_parameter_index ("$TEXT");
	    assert (param_position > 0);
        stmt.bind_text (param_position, text);

        param_position = stmt.bind_parameter_index ("$CHECKSUM");
        assert (param_position > 0);
        stmt.bind_text (param_position, checksum);	    

        ec = stmt.step();
		if (ec != Sqlite.DONE) {
			warning ("Error inserting clipboard entry: %s\n", db.errmsg ());
        }
    }

    public Gee.ArrayList<ClipboardEntry?> get_most_recent_items (int limit = 10) {
        Sqlite.Statement stmt;
        const string prepared_query_str = "SELECT rowid, * FROM entry ORDER BY date_copied DESC LIMIT $LIMIT;";
	    int ec = db.prepare_v2 (prepared_query_str, prepared_query_str.length, out stmt);
	    if (ec != Sqlite.OK) {
		    warning ("Error fetching clipboard entries: %s\n", db.errmsg ());
		    return null;
	    }

        int param_position = stmt.bind_parameter_index ("$LIMIT");
        assert (param_position > 0);
        
        stmt.bind_int (param_position, limit);
        
        var entries = new Gee.ArrayList<ClipboardEntry?> ();
        while ((ec = stmt.step ()) == Sqlite.ROW) {
            ClipboardEntry entry = ClipboardEntry () {
                id = stmt.column_int (0),
                type = (ClipboardEntryType)stmt.column_int (1),
                text = stmt.column_text (4)
            };
            entries.add (entry);
		}
		if (ec != Sqlite.DONE) {
			warning ("Error fetching clipboard entries: %s\n", db.errmsg ());
            return null;
        }
        
        return entries;
    }

    public Gee.ArrayList<ClipboardEntry?> search (string search_term, string? app_search_term = null, int limit = 10) {
        Sqlite.Statement stmt;

        var wildcard_search_term = "%%%s%%".printf (search_term);
        string? wildcard_app_search_term = null;
        if (app_search_term != null) {
            wildcard_app_search_term = "%%%s%%".printf (app_search_term);
        }

        string prepared_query_str = "";
        if (wildcard_app_search_term != null) {
            prepared_query_str = """
                SELECT rowid, * FROM entry 
                WHERE text LIKE $TEXT_SEARCH
                AND application_name LIKE $APP_SEARCH
                ORDER BY date_copied DESC
                LIMIT $LIMIT;
            """;
        } else {
            prepared_query_str = """
                SELECT rowid, * FROM entry
                WHERE text LIKE $TEXT_SEARCH
                ORDER BY date_copied DESC
                LIMIT $LIMIT;
            """;
        }            
	    int ec = db.prepare_v2 (prepared_query_str, prepared_query_str.length, out stmt);
	    if (ec != Sqlite.OK) {
		    warning ("Error searching clipboard entries: %s\n", db.errmsg ());
		    return null;
	    }

        int param_position = stmt.bind_parameter_index ("$TEXT_SEARCH");
        assert (param_position > 0);        
        stmt.bind_text (param_position, wildcard_search_term);

        if (wildcard_app_search_term != null) {
            param_position = stmt.bind_parameter_index ("$APP_SEARCH");
            assert (param_position > 0);        
            stmt.bind_text (param_position, wildcard_app_search_term);
        }

        param_position = stmt.bind_parameter_index ("$LIMIT");
        assert (param_position > 0);        
        stmt.bind_int (param_position, limit);

        var entries = new Gee.ArrayList<ClipboardEntry?> ();
        while ((ec = stmt.step()) == Sqlite.ROW) {
            ClipboardEntry entry = ClipboardEntry () {
                id = stmt.column_int (0),
                type = (ClipboardEntryType)stmt.column_int (1),
                text = stmt.column_text (4)
            };
            entries.add (entry);
		}
		if (ec != Sqlite.DONE) {
			warning ("Error searching clipboard entries: %s\n", db.errmsg ());
            return null;
        }
        
        return entries;
    }

    public void select_item (int id) {
        Sqlite.Statement stmt;
        const string prepared_query_str = "SELECT rowid, * FROM entry WHERE rowid = $ROWID;";
	    int ec = db.prepare_v2 (prepared_query_str, prepared_query_str.length, out stmt);
	    if (ec != Sqlite.OK) {
		    warning ("Error getting clipboard entry for pasting: %s\n", db.errmsg ());
	    }

        int param_position = stmt.bind_parameter_index ("$ROWID");
        assert (param_position > 0);
        
        stmt.bind_int (param_position, id);

        if ((ec = stmt.step ()) == Sqlite.ROW) {
            touch_access_date (id);
            var text = stmt.column_text (4);
            var clipboard = Gtk.Clipboard.get_default (Gdk.Display.get_default ());
            clipboard.set_text (text, -1);
        }
    }

    private void touch_access_date (int id) {
        Sqlite.Statement stmt;
        const string prepared_query_str =
            """UPDATE entry
               SET last_used = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW', 'localtime')
               WHERE rowid = $ROWID;""";
	    int ec = db.prepare_v2 (prepared_query_str, prepared_query_str.length, out stmt);
	    if (ec != Sqlite.OK) {
		    warning ("Error getting clipboard entry for pasting: %s\n", db.errmsg ());
	    }

        int param_position = stmt.bind_parameter_index ("$ROWID");
        assert (param_position > 0);

        stmt.bind_int (param_position, id);

        stmt.step ();
    }
}
