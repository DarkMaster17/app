// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract SocialMedia {
    
    IERC20 public token;

    struct User {
        string name;
        string bio;
        string profilePicture;
        mapping (uint256 => bool) likesReceived;
        mapping(uint256 => bool) likedPosts;
        uint256[] postIds;
        bool isCommissionsOpen;
        uint256 commissionPrice;
    }

    struct Post {
        uint id;
        address creator;
        string content;
        bool isRemoved;
        int256 upvotes;
        int256 downvotes;
    }
    
    struct Comment {
        uint id;
        uint postId;
        address creator;
        string content;
        bool isRemoved;
    }
    
    struct Message {
        address sender;
        address receiver;
        string message;
        uint256 timestamp;
        string fileType;
        bytes fileData;
    }
    
    mapping(uint => uint[]) postComments;
    mapping(address => uint[]) userPosts;
    mapping(address => uint) donations;
    Post[] posts;
    Comment[] comments;
    mapping(address => bool) moderators;
    mapping (address => User) public users;
    mapping(uint256 => Message) public messages;
    uint256 public messageCount;
    mapping(address => address[]) private followedUsers;
    mapping(address => uint256) private userPostCount;

    // ERC20 token contract address
    address public tokenAddress;
    
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }
    
    event PostCreated(uint id, address creator, string content);
    event CommentCreated(uint id, uint postId, address creator, string content);
    event MessageSent(uint id, address sender, address recipient);
    event PostRemoved(uint id, address moderator);
    event CommentRemoved(uint id, address moderator);
    
    // Modifier to check if the caller is a moderator
    modifier onlyModerator() {
        require(moderators[msg.sender], "Caller is not a moderator");
        _;
    }
    
    // Function to add a moderator
    function addModerator(address moderator) public onlyModerator {
        moderators[moderator] = true;
    }
    
    // Function to remove a moderator
    function removeModerator(address moderator) public onlyModerator {
        moderators[moderator] = false;
    }
    
    function setProfile(string memory _name, string memory _bio, string memory _profilePicture) public {
        User storage user = users[msg.sender];
        user.name = _name;
        user.bio = _bio;
        user.profilePicture = _profilePicture;
    }

    function getProfile(address _userAddress) public view returns (string memory, string memory, string memory, bool, uint256) {
        User storage user = users[_userAddress];
        return (user.name, user.bio, user.profilePicture, user.isCommissionsOpen, user.commissionPrice);
    }
     //Function to open commisions
    function openCommissions(uint256 _price) public {
        User storage user = users[msg.sender];
        user.isCommissionsOpen = true;
        user.commissionPrice = _price;
    }
    //Function to close commisions
    function closeCommissions() public {
        User storage user = users[msg.sender];
        user.isCommissionsOpen = false;
    }
    //Function to update commission price
    function updateCommissionPrice(uint256 _price) public {
        User storage user = users[msg.sender];
        user.commissionPrice = _price;
    }

    // Function to follow another user
    function followUser(address userToFollow) public {
        require(userToFollow != msg.sender, "You cannot follow yourself");
         // Check if the user is already being followed
        bool alreadyFollowing = false;
        address[] storage followed = followedUsers[msg.sender];
        for (uint i = 0; i < followed.length; i++) {
            if (followed[i] == userToFollow) {
                alreadyFollowing = true;
                break;
            }
        }
        // Add the user to the list of followed users if not already following
        if (!alreadyFollowing) {
            followedUsers[msg.sender].push(userToFollow);
        }
    }

    // Function to create a post
    function createPost(string memory content) public {
        uint postId = posts.length + 1;
        require(userPostCount[msg.sender] < 3, "Exceeded daily post limit");
        require(IERC20(tokenAddress).transfer(msg.sender, 1), "Token transfer failed");
        posts.push(Post(postId, msg.sender, content, false, 0, 0));
        userPosts[msg.sender].push(postId);
        users[msg.sender].likesReceived[postId] = false;
        emit PostCreated(postId, msg.sender, content);
        userPostCount[msg.sender] += 1;
    }

    // Function to upvote a post
    function upvotePost(uint postId) public {
        require(postId <= posts.length, "Post does not exist");
        Post storage post = posts[postId-1];
        require(!post.isRemoved, "Post has been removed");
        require(!users[msg.sender].likesReceived[postId], "You have already upvoted this post");
        post.upvotes += 1;
        users[msg.sender].likesReceived[postId] = true;
    }

    // Function to downvote a post
    function downvotePost(uint postId) public {
        require(postId <= posts.length, "Post does not exist");
        Post storage post = posts[postId-1];
        require(!post.isRemoved, "Post has been removed");
        require(post.creator != msg.sender, "Cannot downvote own post");
        require(post.downvotes < post.upvotes, "Cannot downvote after upvoting");
        require(!users[msg.sender].likesReceived[postId], "Cannot downvote after upvoting or already downvoted");

        post.downvotes += 1;
        users[msg.sender].likesReceived[postId] = true;
        
        // check if post has received 3 downvotes
        if (post.downvotes % 3 == 0) {
            // deduct 3 tokens from post creator's account
            require(token.balanceOf(post.creator) >= 3, "Post creator does not have enough tokens");
            //token.approve(address(this), 3);
            require(token.transferFrom(post.creator, address(this), 1), "Token transfer failed");
            //post.creatorTokens -= 3;
        }
    }

    
    // Function to create a comment on a post
    function createComment(uint postId, string memory content) public {
        require(postId <= posts.length, "Post does not exist");
        uint commentId = comments.length + 1;
        comments.push(Comment(commentId, postId, msg.sender, content, false));
        postComments[postId].push(commentId);
        emit CommentCreated(commentId, postId, msg.sender, content);
    }
    
    // Function to send a message to another user
    function sendMessage(address _receiver, string memory _message, string memory _fileType, bytes memory _fileData) public {
        messageCount++;
        uint256 messageID = messageCount;
        messages[messageID] = Message(msg.sender, _receiver, _message, block.timestamp, _fileType, _fileData);
    }
    
    // Function to get all posts
    function getPosts() public view returns (Post[] memory) {
        return posts;
    }
    
    // Function to get a user's posts
    function getUserPosts(address user) public view returns (Post[] memory) {
        uint[] memory postIds = userPosts[user];
        Post[] memory result = new Post[](postIds.length);
        for (uint i = 0; i < postIds.length; i++) {
            result[i] = posts[postIds[i]-1];
        }
        return result;
    }
    
    // Function to get all comments on a post
    function getPostComments(uint postId) public view returns (Comment[] memory) {
        uint[] memory commentIds = postComments[postId];
        Comment[] memory result = new Comment[](commentIds.length);
        for (uint i = 0; i < commentIds.length; i++) {
            result[i] = comments[commentIds[i]-1];
        }
        return result;
    }
    
    // Function to get all messages sent
    function getMessage(uint256 _messageID) public view returns (address, string memory, uint256, string memory, bytes memory) {
        return (messages[_messageID].sender, messages[_messageID].message, messages[_messageID].timestamp, messages[_messageID].fileType, messages[_messageID].fileData);
    }
    
    // Function to remove a post
    function removePost(uint postId) public onlyModerator {
        require(postId <= posts.length, "Post does not exist");
        posts[postId-1].isRemoved = true;
        emit PostRemoved(postId, msg.sender);
    }
    
    // Function to remove a comment
    function removeComment(uint commentId) public onlyModerator {
        require(commentId <= comments.length, "Comment does not exist");
        comments[commentId-1].isRemoved = true;
        emit CommentRemoved(commentId, msg.sender);
    }

    // Function to get token ballance
    function getTokenBalance(address _account) public view returns (uint256) {
        return token.balanceOf(_account);
    }
    
     //Function to transfer tokens
    function transferTokens(address recipient, uint256 amount) public {
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(token.transfer(recipient, amount), "Transfer failed");
    }
}
