<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="Đăng nhập"/>
<c:set var="pageStylesheet" value="/assets/css/gdDangNhap.css"/>
<%@ include file="/WEB-INF/view/dungchung/header.jspf" %>
<section class="panel login-panel">
    <h1>Đăng nhập</h1>
    <c:if test="${not empty error}">
        <p class="notice error" role="alert"><c:out value="${error}"/></p>
    </c:if>
    <form class="login-form" method="post" action="<c:url value='/login'/>">
        <label class="field">Tên đăng nhập
            <input name="username" maxlength="80" autocomplete="username" required value="<c:out value="${username}"/>">
        </label>
        <label class="field">Mật khẩu
            <input type="password" name="password" maxlength="256" autocomplete="current-password" required>
        </label>
        <button type="submit">Đăng nhập</button>
    </form>
</section>
<%@ include file="/WEB-INF/view/dungchung/footer.jspf" %>
