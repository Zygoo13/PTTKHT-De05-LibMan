<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="Trang chủ"/>
<c:set var="homeView" value="${true}"/>
<c:set var="pageStylesheet" value="/assets/css/gdChinh.css"/>
<%@ include file="/WEB-INF/view/dungchung/header.jspf" %>
<h1 class="module-title">Trang chủ Thư viện PTIT</h1>
<section class="panel home-panel">
    <p>Xin chào, <strong><c:out value="${sessionScope.fullName}"/></strong>.</p>
    <c:choose>
        <c:when test="${sessionScope.account.role eq 'READER'}">
            <a class="button" href="<c:url value='/documents'/>">Tìm kiếm tài liệu</a>
        </c:when>
        <c:when test="${sessionScope.account.role eq 'MANAGER'}">
            <a class="button" href="<c:url value='/reports/readers'/>">Thống kê độc giả</a>
        </c:when>
    </c:choose>
</section>
<%@ include file="/WEB-INF/view/dungchung/footer.jspf" %>
