<%@page import="org.apache.commons.lang3.*"%>
<%@page import="java.text.CharacterIterator"%>
<%@page import="java.io.IOException"%>
<%@page import="java.util.Arrays"%>
<%@page import="java.security.SecureRandom"%>
<%@page import="javax.crypto.spec.PBEKeySpec"%>
<%@page import="javax.crypto.SecretKeyFactory"%>
<%@page import="java.security.spec.KeySpec"%>
<%@page import="java.lang.Object.*"%>


<html >
    <head>
        <title>Book Query</title>
        <meta http-equiv="Content-Type" content="text/html; carset=UTF-8">
        <link rel="stylesheet" href="style.css" type="text/css">
    </head
    <div class="container">
        <body>
            <%
                // bookstore
                // declare variables
                String authors = "placeholder";
                String title = null;
                String username = null;
                int bookID = 0;
                String customerID = "00000";
                String author = "placeholder";
                int quant = 0;
                byte[] encrPassword;
                String password;
                byte[] salt;


            %>



            <div class="nav-bar">
                <div class="header">
                    <h1>Tiny E-Bookstore</h1>
                    </div>
            </div>
            <div class="selection">
                <h3>Please make a selection from the books we have in stock!</h3>
            </div>
        <c:out value="${'Hello! This is the <c:out>'}"/>

        <table>
            <tr>  <!-- set up column titles-->
                <td><h4>Book ID</h4></td>
                <td><h4>Title</h4></td>
                <td><h4>Author</h4></td>
                <td><h4>Price</h4></td>
                <td><h4>In Stock</h4></td>
                <td><h4>Add to wishlist?</h4></td>
            </tr>

            <%@ page import = "java.sql.*" %>
            <%      Class.forName("com.mysql.jdbc.Driver");
                String dbURL = "jdbc:mysql://bookstore.ckccbr98ixeu.eu-west-1.rds.amazonaws.com:3306/";
                String user = "masterUser";
                String dbpassword = "pass123!";
                String dbName = "ebdb";

                // connect to AWS RDS using above credentials
                Connection conn = DriverManager.getConnection(dbURL + dbName, user, dbpassword);

                // declare prepared statement
                PreparedStatement statement;

                String query = "SELECT bookID, title, author, price, quant FROM books";
                statement = conn.prepareStatement(query);
                ResultSet rs = statement.executeQuery();
                // while there are still rows in the table, print below values
                while (rs.next()) {
                    bookID = rs.getInt("bookID");
                    title = rs.getString("title");
                    author = rs.getString("author");
                    float price = rs.getFloat("price");
                    quant = rs.getInt("quant");
            %> 
            <tr><form method="post">
                <td width ="200" ><%=bookID%></td>  
                <td><%=title%></td>
                <td width ="150"><%=author%></td>
                <td><%=price%></td>
                <td><center><%=quant%></center></td>
                <td><center><input type="radio" name="title" value="<%=title%>"></center> </td>
                </tr>
                <%
                    }
                %>
                <tr>
                    <td><input type="text" name="username" placeholder="username, no special characters" 
                               max="30" size="25"></td>
                    <td><input type="password" name="password" placeholder="please enter password" 
                               max="20"></td>
                    <td><input type="submit" value="Submit"></td>
            </form>
            </tr>
        </table>
        <%
            // retrieve values for title and username
            title = request.getParameter("title");
            title = StringEscapeUtils.escapeHtml4(title);
            username = request.getParameter("username");
            username = StringEscapeUtils.escapeHtml4(username);
            password = request.getParameter("password");
            password = StringEscapeUtils.escapeHtml4(password);

        %>
        <div class='login'>
            <br>Enter your login credentials to save a book to your wishlist.
            <br> If you don't have an account, one will be created for you. 
        </div>
        <%
            // only process below commands if a title and a
            // username submitted
            if (title != null && !title.isEmpty() && username != null
                    && !username.isEmpty() && password != null && !password.isEmpty()) {

                try {
                    // retrieve bookID using title
                    query = "SELECT bookID FROM books WHERE title = ?";
                    statement = conn.prepareStatement(query);
                    statement.setString(1, title);
                    rs = statement.executeQuery();
                    while (rs.next()) {
                        bookID = rs.getInt("bookID");
                    }
                    // retrieve customerID using userName
                    query = "SELECT customerID, password, salt FROM customers WHERE username = ?";
                    statement = conn.prepareStatement(query);
                    statement.setString(1, username);
                    rs = statement.executeQuery();
                    if (rs.next()) {
                        customerID = rs.getString("customerID");
                        encrPassword = rs.getBytes("password");
                        salt = rs.getBytes("salt");

                        String algorithm = "PBKDF2WithHmacSHA1";
                        // SHA-1 generates 160 bit hashes
                        int derivedKeyLength = 160;
                        int iterations = 20000;
                        KeySpec spec = new PBEKeySpec(password.toCharArray(), salt, iterations, derivedKeyLength);
                        SecretKeyFactory f = SecretKeyFactory.getInstance(algorithm);
                        byte[] newEncrPassword = f.generateSecret(spec).getEncoded();

                        if (Arrays.equals(newEncrPassword, encrPassword)) {
                            // insert row into wishlist using above foreign keys
                            query = "INSERT INTO wishlist (customerID, bookID) VALUES (?, ?)";
                            statement = conn.prepareStatement(query);
                            statement.setString(1, customerID);
                            statement.setInt(2, bookID);
                            statement.executeUpdate();
                            %><br><br> <div class="login">Thank you <%=username%>! You added <%=title%> to your wishlist. </div><br> <%
                            title = "";
                            username = "";
                            password = "";

                        }

                    } else {
        %>Thank you <%=username%> for your interest! A new account has been created for you.
        <br> <%=title%> has been added to your wishlist!<%
                SecureRandom random = SecureRandom.getInstance("SHA1PRNG");
                // Generate a 8 byte (64 bit) salt
                byte[] dsalt = new byte[8];
                random.nextBytes(dsalt);

                // use the salt to hash the password prior to inserting to table
                String algorithm = "PBKDF2WithHmacSHA1";
                // SHA-1 generates 160 bit hashes
                int derivedKeyLength = 160;
                int iterations = 20000;
                KeySpec spec = new PBEKeySpec(password.toCharArray(), dsalt, iterations, derivedKeyLength);
                SecretKeyFactory f = SecretKeyFactory.getInstance(algorithm);
                encrPassword = f.generateSecret(spec).getEncoded();

                // insert row into customers using above foreign keys
                query = "INSERT INTO customers (username, password, salt) "
                        + "VALUES (?, ?, ?)";
                statement = conn.prepareStatement(query);
                statement.setString(1, username);
                statement.setBytes(2, encrPassword);
                statement.setBytes(3, dsalt);
                statement.executeUpdate();

                // retrieve customerID using userName
                query = "SELECT customerID FROM customers WHERE username = ?";
                statement = conn.prepareStatement(query);
                statement.setString(1, username);
                rs = statement.executeQuery();
                if (rs.next()) {
                    customerID = rs.getString("customerID");
                }

                // insert row into wishlist 
                query = "INSERT INTO wishlist (customerID, bookID) VALUES (?, ?)";
                statement = conn.prepareStatement(query);
                statement.setString(1, customerID);
                statement.setInt(2, bookID);
                statement.executeUpdate();

                title = "";
                username = "";
                password = "";
            }
        } catch (Exception e) {
        %>Error<%
        }

    } else {
        %> 
        <div class="login">
            Please enter all fields 
        </div>    
        <%
    }
        %>


        <%
            // close connections
            rs.close();
            statement.close();
            conn.close();

        %>
        <br>

        </body>
    </div>
</html>
