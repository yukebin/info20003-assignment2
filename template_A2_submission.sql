-- __/\\\\\\\\\\\__/\\\\\_____/\\\__/\\\\\\\\\\\\\\\____/\\\\\_________/\\\\\\\\\_________/\\\\\\\________/\\\\\\\________/\\\\\\\________/\\\\\\\\\\________________/\\\\\\\\\_______/\\\\\\\\\_____        
--  _\/////\\\///__\/\\\\\\___\/\\\_\/\\\///////////___/\\\///\\\_____/\\\///////\\\_____/\\\/////\\\____/\\\/////\\\____/\\\/////\\\____/\\\///////\\\_____________/\\\\\\\\\\\\\___/\\\///////\\\___       
--   _____\/\\\_____\/\\\/\\\__\/\\\_\/\\\____________/\\\/__\///\\\__\///______\//\\\___/\\\____\//\\\__/\\\____\//\\\__/\\\____\//\\\__\///______/\\\_____________/\\\/////////\\\_\///______\//\\\__      
--    _____\/\\\_____\/\\\//\\\_\/\\\_\/\\\\\\\\\\\___/\\\______\//\\\___________/\\\/___\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\_________/\\\//_____________\/\\\_______\/\\\___________/\\\/___     
--     _____\/\\\_____\/\\\\//\\\\/\\\_\/\\\///////___\/\\\_______\/\\\________/\\\//_____\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\________\////\\\____________\/\\\\\\\\\\\\\\\________/\\\//_____    
--      _____\/\\\_____\/\\\_\//\\\/\\\_\/\\\__________\//\\\______/\\\______/\\\//________\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\___________\//\\\___________\/\\\/////////\\\_____/\\\//________   
--       _____\/\\\_____\/\\\__\//\\\\\\_\/\\\___________\///\\\__/\\\______/\\\/___________\//\\\____/\\\__\//\\\____/\\\__\//\\\____/\\\___/\\\______/\\\____________\/\\\_______\/\\\___/\\\/___________  
--        __/\\\\\\\\\\\_\/\\\___\//\\\\\_\/\\\_____________\///\\\\\/______/\\\\\\\\\\\\\\\__\///\\\\\\\/____\///\\\\\\\/____\///\\\\\\\/___\///\\\\\\\\\/_____________\/\\\_______\/\\\__/\\\\\\\\\\\\\\\_ 
--         _\///////////__\///_____\/////__\///________________\/////_______\///////////////_____\///////________\///////________\///////_______\/////////_______________\///________\///__\///////////////__

-- Your Name: Kevin Yu
-- Your Student Number: 1462539
-- By submitting, you declare that this work was completed entirely by yourself.

-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q1

SELECT postPermanentID, text
FROM post
WHERE postPermanentID NOT IN (
	SELECT DISTINCT postID
    FROM react);

-- END Q1
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q2

SELECT moderator.modID, user.username, moderator.dateModStatus
FROM moderator INNER JOIN user ON moderator.linkedUserID = user.userID
ORDER BY moderator.dateModStatus DESC
LIMIT 1;

-- END Q2
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q3

SELECT postPermanentID, viewCount
FROM post
WHERE viewCount > 9000 AND authorID = (
	SELECT userID
    FROM user
    WHERE username = 'axe');

-- END Q3
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q4

SELECT originalPostID AS postPermanentID, COUNT(replyPostID) AS totalCommentCount
FROM postreply
GROUP BY originalPostID
HAVING COUNT(replyPostID) = (
  SELECT MAX(totalCount)
  FROM (
    SELECT COUNT(replyPostID) AS totalCount
    FROM postreply
    GROUP BY originalPostID
  ) AS commentcount
);

-- END Q4
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q5

SELECT atch.dataURL, channel.channelID
FROM attachmentobject AS atch 
	INNER JOIN post ON atch.postPermanentID = post.postPermanentID
	INNER JOIN postchannel ON post.postPermanentID = postchannel.postID
	INNER JOIN channel ON postchannel.channelID = channel.channelID
WHERE channel.channelName LIKE '%dota2%';

-- END Q5
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q6

SELECT channel.channelName, COUNT(react.emoji) AS heartCount
FROM react
	INNER JOIN post ON react.postID = post.postPermanentID
	INNER JOIN postchannel ON post.postPermanentID = postchannel.postID
	INNER JOIN channel ON postchannel.channelID = channel.channelID
WHERE react.emoji = 'love'
GROUP BY channel.channelID
HAVING COUNT(react.emoji) = (
	SELECT MAX(heartCountPerChannel)
		FROM (
			SELECT COUNT(react.emoji) AS heartCountPerChannel
			FROM react
				INNER JOIN post ON react.postID = post.postPermanentID
				INNER JOIN postchannel ON post.postPermanentID = postchannel.postID
				INNER JOIN channel ON postchannel.channelID = channel.channelID
			WHERE react.emoji = 'love'
			GROUP BY channel.channelID
		) AS channelheartcount);

-- END Q6
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q7

SELECT user.userID, user.reputation, 
	COUNT(DISTINCT moderatorreport.caseID) AS totalModeratorReports, 
    COUNT(CASE WHEN react.emoji = 'love' THEN 1 END) AS totalLoveReacts
FROM user
	INNER JOIN post ON user.userID = post.authorID
	LEFT JOIN react ON post.postPermanentID = react.postID
	LEFT JOIN moderatorreport ON post.postPermanentID = moderatorreport.postPermanentID
WHERE user.reputation < 60
GROUP BY user.userID
HAVING totalLoveReacts >= 3 AND totalModeratorReports >= 1;

-- END Q7
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q8

-- Note: I did not use the straight forward approach of using IN since LIMIT cannot be in subquery
SELECT channel.channelID, channel.channelName, SUM(atch.virusScanned) AS totalVirusInfectedAttachments
FROM channel
	INNER JOIN postchannel ON channel.channelID = postchannel.channelID
	INNER JOIN post ON postchannel.postID = post.postPermanentID
	INNER JOIN attachmentobject AS atch ON post.postPermanentID = atch.postPermanentID
GROUP BY channel.channelID
HAVING totalVirusInfectedAttachments >= (
    SELECT MIN(virusCount)
    FROM (
        SELECT SUM(atch.virusScanned) AS virusCount
        FROM channel
			INNER JOIN postchannel ON channel.channelID = postchannel.channelID
			INNER JOIN post ON postchannel.postID = post.postPermanentID
			INNER JOIN attachmentobject AS atch ON post.postPermanentID = atch.postPermanentID
        GROUP BY channel.channelID
        ORDER BY virusCount DESC
        LIMIT 3
    ) AS top3)
ORDER BY totalVirusInfectedAttachments DESC;

-- END Q8
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q9

SELECT moderatorreport.modID, COUNT(moderatorreport.caseID) AS numberOfDisciplinariesToRepeaters
FROM moderatorreport
	INNER JOIN post ON moderatorreport.postPermanentID = post.postPermanentID
	INNER JOIN (
		-- Subquery to identify repeaters
		SELECT user.userID
		FROM user
			INNER JOIN post ON user.userID = post.authorID
			INNER JOIN postchannel ON post.postPermanentID = postchannel.postID
            -- only keeps those reported with inner join
			INNER JOIN moderatorreport ON post.postPermanentID = moderatorreport.postPermanentID 
		GROUP BY user.userID
		HAVING COUNT(DISTINCT postchannel.channelID) > 1
	) AS repeaters ON post.authorID = repeaters.userID
WHERE moderatorreport.disciplinaryAction = 1
GROUP BY moderatorreport.modID;

-- END Q9
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q10

SELECT user.userID
FROM user
	INNER JOIN post ON user.userID = post.authorID
    INNER JOIN postchannel ON post.postPermanentID = postchannel.postID
    INNER JOIN channel ON postchannel.channelID = channel.channelID
WHERE post.dateCreated < '2024-04-01' AND channel.channelName = 'ranked_grind';

SELECT userID
FROM user
	INNER JOIN post ON user.userID = post.authorID
    LEFT JOIN postreply ON post.postPermanentID = postreply.originalPostID
    INNER JOIN postchannel ON post.postPermanentID = postchannel.postID
    INNER JOIN channel ON postchannel.channelID = channel.channelID
WHERE post.dateCreated >= '2024-04-01' AND postreply.replyPostID IN (
	SELECT post.postPermanentID
	FROM post 
		INNER JOIN postchannel ON post.postPermanentID = postchannel.postID
		INNER JOIN channel ON postchannel.channelID = channel.channelID
	WHERE channel.channelName = 'dota2_memes'
);

-- END Q10
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- END OF ASSIGNMENT Do not write below this line