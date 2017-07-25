import java.sql.*;

// Remember that part of your mark is for doing as much in SQL (not Java) 
// as you can. At most you can justify using an array, or the more flexible
// ArrayList. Don't go crazy with it, though. You need it rarely if at all.
import java.util.ArrayList;

public class Assignment2 {

    // A connection to the database
    Connection connection;

    Assignment2() throws SQLException {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    /**
     * Connects to the database and sets the search path.
     * 
     * Establishes a connection to be used for this session, assigning it to the
     * instance variable 'connection'. In addition, sets the search path to
     * markus.
     * 
     * @param url
     *            the url for the database
     * @param username
     *            the username to be used to connect to the database
     * @param password
     *            the password to be used to connect to the database
     * @return true if connecting is successful, false otherwise
     */
    public boolean connectDB(String URL, String username, String password) {
        // setting up connection with given parameters. 
	// Handle connection fail
        try{
	connection = DriverManager.getConnection(URL,username,password);
	if (connection == null) return false;

	//setting search path
	PreparedStatement ps;
	String setPath = "SET search_path TO markus";
	ps = connection.prepareStatement(setPath);
	ps.execute();
	
	//return true;
	}
	catch(SQLException se){
	}
	return true;
    }

    /**
     * Closes the database connection.
     * 
     * @return true if the closing was successful, false otherwise
     */
    public boolean disconnectDB() {
        // call close() method to disconnect from database
	try{
	connection.close();
	// check if successfully disconnected
        boolean status = connection.isClosed();
	if (status) return true;
	}
	catch(SQLException se){}
	return false;
    }

    /**
     * Assigns a grader for a group for an assignment.
     * 
     * Returns false if the groupID does not exist in the AssignmentGroup table,
     * if some grader has already been assigned to the group, or if grader is
     * not either a TA or instructor.
     * 
     * @param groupID
     *            id of the group
     * @param grader
     *            username of the grader
     * @return true if the operation was successful, false otherwise
     */
    public boolean assignGrader(int groupID, String grader) {
        //ALL of the specified conditions must be satisfied, 
	//therefore this method will check each boolean as soon as 
	//they get evaluated
	try{
	//Set up operation variables
	PreparedStatement ps;
	Statement stat = connection.createStatement();
	ResultSet rs;
	
	//prepare boolean variables for each condition as specified above
	boolean group_already_assigned = false;
	boolean invalid_group_id = true;
	boolean invalid_grader = true;
		
	// Find out if groupID is already assigned to some grader
	String checkAssignedGroupID = "SELECT group_id FROM Grader";
	ps = connection.prepareStatement(checkAssignedGroupID);
	rs = ps.executeQuery();

	// Iterate through the result set and evaluate group_already_assigned
	while (rs.next()){
		int GID = rs.getInt("group_id");
		if(groupID == GID) {
			group_already_assigned = true;
			break;		
		}
	}

	// Checking whether a condition is met
	if (group_already_assigned) return false;

	// Partially satisfied, Continue to find out if groupID is invalid
	String checkInvalidGroupID = "SELECT group_id FROM AssignmentGroup";
        ps = connection.prepareStatement(checkInvalidGroupID);
        rs = ps.executeQuery();

	// Iterate through the result set and evaluate invalid_group_id
        while (rs.next()){
                int GID = rs.getInt("group_id");
		if(groupID == GID){
			invalid_group_id = false;
			break;
		}
        }

	// Checking second condition
	if (invalid_group_id) return false;

	// Continue to find out if grader is invalid
        String checkInvalidGrader = "SELECT username FROM MarkusUser "
					+ "WHERE type = 'TA'";
        ps = connection.prepareStatement(checkInvalidGrader);
        rs = ps.executeQuery();
	
        // Iterate through the result set and evaluate invalid_group_id
        while (rs.next()){
                String TAs = rs.getString("username");
		if(grader.compareTo(TAs)==0) {
			invalid_grader = false;
			break;
		}
        }

	// Checking the last condition 
	if (invalid_grader) return false;

	// All conditions are met, insert the pair to Grader Table 
	String insertPair = "INSERT INTO Grader (group_id,username) VALUES (" + groupID 
				+ ",'" + grader + "')";
	
	//System.out.println(insertPair);
	
	ps = connection.prepareStatement(insertPair);
	ps.executeQuery();
	rs = stat.executeQuery(insertPair);
	}
	catch(SQLException se){
	}
	return true;
    }

    /**
     * Adds a member to a group for an assignment.
     * 
     * Records the fact that a new member is part of a group for an assignment.
     * Does nothing (but returns true) if the member is already declared to be
     * in the group.
     * 
     * Does nothing and returns false if any of these conditions hold: - the
     * group is already at capacity, - newMember is not a valid username or is
     * not a student, - there is no assignment with this assignment ID, or - the
     * group ID has not been declared for the assignment.
     * 
     * @param assignmentID
     *            id of the assignment
     * @param groupID
     *            id of the group to receive a new member
     * @param newMember
     *            username of the new member to be added to the group
     * @return true if the operation was successful, false otherwise
     */
    public boolean recordMember(int assignmentID, int groupID, String newMember) {
       try{
	//Set up operation variables
        PreparedStatement ps;
        ResultSet rs;
	Statement stat = connection.createStatement();

        //prepare boolean variables for each condition as specified above
        boolean group_max_cap = false;
        boolean invalid_user = true;
        boolean invalid_aid = true;
	boolean group_undeclared = true;
	boolean member_already_declared = false;
	// Checks invalid usernames
	String userNotValid = "SELECT username " + 
				"FROM MarkusUser WHERE type = 'student'";
        ps = connection.prepareStatement(userNotValid);
        rs = ps.executeQuery();
        // Iterate through the result set and evaluate invalid_user
        while (rs.next()){
                String students = rs.getString("username");
                if(students.compareTo(newMember) == 0){ 
			invalid_user = false;
			break;
		}
        }
	//System.out.println(invalid_user?"username INVALID":"username valid");
        // Checking whether a condition is met
        if (invalid_user) return false;
	
	// Continue to check invalid assignment_id 	
	String checkInvalidAID = "SELECT assignment_id FROM Assignment";
        ps = connection.prepareStatement(checkInvalidAID);
        rs = ps.executeQuery();

        // Iterate through the result set and evaluate invalid_aid
        while (rs.next()){
                int AID = rs.getInt("assignment_id");
                if(AID == assignmentID){
                        invalid_aid = false;
                        break;
                }
        }
	 ////System.out.println(invalid_aid?"AID INVALID":"AID valid");
        // Checking whether a condition is met
        if (invalid_aid) return false;
	
	// Continue to check undeclared group_id
	String checkUndeclaredGroup = "SELECT group_id FROM AssignmentGroup";
        ps = connection.prepareStatement(checkUndeclaredGroup);
        rs = ps.executeQuery();

        // Iterate through the result set and evaluate group_undeclared
        while (rs.next()){
                int GID = rs.getInt("group_id");
                if(GID == groupID){
                        group_undeclared = false;
                        break;
                }
        }
	 ///System.out.println(group_undeclared?"Group DNE":"Group VALID");
        if (group_undeclared) return false;
	
	// Continue to check group is full
	String checkGroupFull = "SELECT group_id " 
	+ "FROM Assignment NATURAL JOIN AssignmentGroup "
	+ "WHERE assignment_id = " + assignmentID + " AND group_max <= "
	+ "(SELECT count(username) FROM Membership NATURAL JOIN AssignmentGroup " 
	+ "WHERE assignment_id = " + assignmentID + " AND group_id = " + groupID
	+ " GROUP BY group_id)";
	ps = connection.prepareStatement(checkGroupFull);
	//ps.setInt(1,assignmentID);
        rs = ps.executeQuery();

        // Iterate through the result set and evaluate group_max_cap
        while (rs.next()){
                int GID = rs.getInt("group_id");
                if(GID == groupID){
                        group_max_cap = true;
                        break;
                }
        }
	/// System.out.println(group_max_cap?"Group FULL":"Spot Available");
        if (group_max_cap) return false; 	
	
	//====================Return True Case=========================
	
	//Check if member is already declared
	String checkMemberDeclared = "SELECT username FROM Membership "
	+ "WHERE group_id = " + groupID;
	ps = connection.prepareStatement(checkMemberDeclared);
	//ps.setInt(1,groupID);
        rs = ps.executeQuery();
        // Iterate through the result set and evaluate member_already_delcared
        while (rs.next()){
                String member = rs.getString("username");
                if(newMember.compareTo(member)==0){
                        member_already_declared = true;
                        break;
                }
        }
	/// System.out.println(member_already_declared?"Already Belong":"Aloner");
        if (member_already_declared) return true;
	
	//ALL conditions are met, insert new tuple into Membership table
	String insert = "INSERT INTO Membership (username,group_id) VALUES ("
	+ "'" + newMember + "'," + groupID + ")";	
	//System.out.println(insert);

	ps = connection.prepareStatement(insert);
	//ps.executeQuery();
	rs = stat.executeQuery(insert);
	//System.out.println(insert);
	}
	//System.out.println(insert);
	catch(SQLException se){}
		
	return true;
    }

    /**
     * Creates student groups for an assignment.
     * 
     * Finds all students who are defined in the Users table and puts each of
     * them into a group for the assignment. Suppose there are n. Each group
     * will be of the maximum size allowed for the assignment (call that k),
     * except for possibly one group of smaller size if n is not divisible by k.
     * Note that k may be as low as 1.
     * 
     * The choice of which students to put together is based on their grades on
     * another assignment, as recorded in table Results. Starting from the
     * highest grade on that other assignment, the top k students go into one
     * group, then the next k students go into the next, and so on. The last n %
     * k students form a smaller group.
     * 
     * In the extreme case that there are no students, does nothing and returns
     * true.
     * 
     * Students with no grade recorded for the other assignment come at the
     * bottom of the list, after students who received zero. When there is a tie
     * for grade (or non-grade) on the other assignment, takes students in order
     * by username, using alphabetical order from A to Z.
     * 
     * When a group is created, its group ID is generated automatically because
     * the group_id attribute of table AssignmentGroup is of type SERIAL. The
     * value of attribute repo is repoPrefix + "/group_" + group_id
     * 
     * Does nothing and returns false if there is no assignment with ID
     * assignmentToGroup or no assignment with ID otherAssignment, or if any
     * group has already been defined for this assignment.
     * 
     * @param assignmentToGroup
     *            the assignment ID of the assignment for which groups are to be
     *            created
     * @param otherAssignment
     *            the assignment ID of the other assignment on which the
     *            grouping is to be based
     * @param repoPrefix
     *            the prefix of the URL for the group's repository
     * @return true if successful and false otherwise
     */
    public boolean createGroups(int assignmentToGroup, int otherAssignment,
            String repoPrefix) {
        // Replace this return statement with an implementation of this method!
        try{
		PreparedStatement ps;
		ResultSet rs;
		Statement stat = connection.createStatement();

		boolean invalid_asmt = true;
		boolean invalid_otherasmt = true;

		//check if vaild assignment_id and other assignment_id
		String sValid = "SELECT assignment_id FROM Assignment";
		ps = connection.prepareStatement(sValid);
		rs = ps.executeQuery();
		while (rs.next()){
			int asmt = rs.getInt(1);
			if(asmt == assignmentToGroup){
				invalid_asmt = false;
			}
			if(asmt == otherAssignment){
				invalid_otherasmt = false;
			}
		}
	
		if(invalid_asmt) return false;
		else if(invalid_otherasmt) return false;

		//get size of group
		String sizeofgroup = "SELECT group_max FROM Assignment "
		+ "WHERE assignment_id = " + assignmentToGroup;

		ps = connection.prepareStatement(sizeofgroup);
		rs = ps.executeQuery();
					
		int groupSize = rs.getInt(1);
	
		//get the results of other assignment in order of grade
		String s1 = "SELECT T3.username, T2.mark FROM AssignmentGroup T1 " 
		+ "LEFT JOIN Result T2 ON T1.group_id = T2.group_id "
		+ "INNER JOIN Membership T3 ON T1.group_id = T3.group_id "
		+ "WHERE assignment_id = " + otherAssignment
		+ " ORDER BY T2.mark, T3.username";
	
		ps = connection.prepareStatement(s1);
		rs = ps.executeQuery();
		//stat.executeQuery();
		ResultSet val = stat.executeQuery("SELECT setval('group_id_seq',max(group_id)) FROM AssignmentGroup;");
	
		int i = 1;
		int gval = val.getInt(1);

		String insG = "INSERT INTO AssignmentGroup (assignment_id, repo) VALUES ('"
		+ assignmentToGroup + "', '"
		+ repoPrefix + "/group_"+gval +"');";//fix repoUrl
	
		String insMem = "INSERT INTO Membership (username, group_id) VALUES ('"
		+ rs.getString("username") + "', 'group_" +gval +"');";

		while(rs.next()){
			if(i == 1){
				stat.executeQuery(insG); 
				i++;
			}else if(i == groupSize){
				i = 1;
				gval++;
			}
			stat.executeQuery(insMem);						
		}	
	}
	catch (SQLException se){}

       return true;
	
    }

    public static void main(String[] args) {
        // You can put testing code in here. It will not affect our autotester.
    	try{
	Assignment2 ass = new Assignment2();	

	String url = "jdbc:postgresql://localhost:5432/csc343h-parknay1";
	String username = "parknay1";
	String password = "";
	
	boolean connectTrue = ass.connectDB(url,username,password);
	System.out.println(connectTrue?"connected":"connection failed");
		
	boolean a1;
	//==============test cases for assignGrader===============
	//group already assigned
	a1 = ass.assignGrader(2001, "t1");
	System.out.println(a1?"out:successful":"out:value invalid");
	//groupID invalid
        a1 = ass.assignGrader(3334, "t1");
        System.out.println(a1?"out:successful":"out:value invalid");
	//grader invalid
        a1 = ass.assignGrader(3333, "s1");
        System.out.println(a1?"out:successful":"out:value invalid");
	//successful case
        a1 = ass.assignGrader(3333, "t1");
        System.out.println(a1?"out:successful":"out:value invalid");
	
	 //==============test cases for recordMember===============
        //group full
	System.out.println("TESTING recordMember");
        a1 = ass.recordMember(1000, 2005,"s100");
        System.out.println(a1?"out:successful":"out:value invalid2");
        //username invalid
        a1 = ass.recordMember(1000, 2030, "abc");
        System.out.println(a1?"out:successful":"out:value invalid");
        //assignment_id invalid
        a1 = ass.recordMember(1234, 2030, "s100");
        System.out.println(a1?"out:successful":"out:value invalid");
        //group not declared 
        a1 = ass.recordMember(1000, 5555, "s100");
        System.out.println(a1?"out:successful":"out:value invalid");
	//successful case -> student already belong to that group
	a1 = ass.recordMember(1000, 2001, "s2");
        System.out.println(a1?"out:successful":"out:value invalid");
	//successful case -> all conditions met
	a1 = ass.recordMember(1000, 2008, "s100");
        System.out.println(a1?"out:successful":"out:value invalid");
	

	
 
	a1 = ass.disconnectDB();
	System.out.println(a1?"disconnected":"disconnection failed");
	}
	catch (SQLException se){}
    }
}